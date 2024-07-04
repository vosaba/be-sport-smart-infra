# Be Sport Smart (IaC) Repository

## Overview
This repository contains Terraform configurations for provisioning and managing infrastructure on Azure for the "Be Sport Smart" project. It supports two types of environments:

1.  **Free Tier Environment** (currently used): Uses only free Azure resources.
    - **Microservices** based on k8s.
2.  **Paid Tier Environment**: Utilizes paid Azure services.
    - **Two applications** for back-end and front-end services.

## Directory Structure

-   `.github/workflows`: Contains GitHub Actions workflows for CI/CD.
    
    -   `cd.yml`: CD pipeline for continuous deployment. This pipeline deploys the infrastructure to Azure after manual approval.
    -   `ci.yml`: CI pipeline for continuous integration. Essentially, it validates the Terraform configuration and prints the Terraform plan.
-   `environments/azure/2_apps_free_tier`: Terraform configurations for the free tier environment.
    
    -   `backend.tf`: Configuration for remote state storage.
    -   `main.tf`: Main Terraform configuration file.
    -   `terraform.tfvars`: Variables specific to the free tier environment.
    -   `variables.tf`: Definition of input variables.
-   `environments/azure/k8s_mss_paid_tier`: Directory for the paid tier environment configurations.
    
-   `modules/azure`: Contains reusable Terraform modules.
    
    -   `aks`: Azure Kubernetes Service module.
    -   `app_service_dotnet`: Azure App Service for .NET applications module.
    -   `app_service_node`: Azure App Service for Node.js applications module.
    -   `app_service_plan`: Module for creating App Service plans.
    -   `app_service_source_control`: Module for integrating App Services with source control.
    -   `application_gateway`: Azure Application Gateway module.
    -   `application_insights`: Azure Application Insights module.
    -   `container_registry`: Azure Container Registry module.
    -   `cosmos_db`: Azure Cosmos DB module.
    -   `key_vault`: Azure Key Vault module.
    -   `log_analytics`: Azure Log Analytics module.
    -   `postgresql_flexible_server`: Azure PostgreSQL Flexible Server module.
    -   `postgresql_server`: Azure PostgreSQL Server module.
    -   `public_ip`: Module for creating public IP addresses.
    -   `resource_group`: Module for creating resource groups.
    -   `user_assigned_identity`: Module for creating user-assigned identities.
    -   `virtual_network`: Module for creating virtual networks.
-   `.gitignore`: Git ignore file.
    
-   `README.md`: This file. 😊
    

## Free Tier Environment Details

The free tier environment provisions the following resources:

### Resource Group

    `resource "azurerm_resource_group" "rg" {
      name     = azurecaf_name.rg_name.result
      location = var.location
      tags     = local.tags
    }` 

### Application Insights

    `module "application_insights" {
      source           = "../../../modules/azure/application_insights"
      location         = var.location
      rg_name          = azurerm_resource_group.rg.name
      environment_name = var.environment
      workspace_id     = module.log_analytics.LOGANALYTICS_WORKSPACE_ID
      tags             = azurerm_resource_group.rg.tags
      resource_token   = local.resource_token
    }` 

### Log Analytics

    `module "log_analytics" {
      source         = "../../../modules/azure/log_analytics"
      location       = var.location
      rg_name        = azurerm_resource_group.rg.name
      tags           = azurerm_resource_group.rg.tags
      resource_token = local.resource_token
    }` 

### Key Vault

    `module "key_vault" {
      source                   = "../../../modules/azure/key_vault"
      location                 = var.location
      principal_id             = data.azurerm_client_config.current.object_id
      rg_name                  = azurerm_resource_group.rg.name
      tags                     = azurerm_resource_group.rg.tags
      resource_token           = local.resource_token
      access_policy_object_ids = [module.backend_app.IDENTITY_PRINCIPAL_ID]
      secrets = [
        {
          name  = local.pg_username
          value = module.postgresql_flexible_server.AZURE_PG_USERNAME
        },
        {
          name  = local.pg_password
          value = module.postgresql_flexible_server.AZURE_PG_PASSWORD
        }
      ]
    }` 

### PostgreSQL Flexible Server

    `module "postgresql_flexible_server" {
      source         = "../../../modules/azure/postgresql_flexible_server"
      location       = var.location
      rg_name        = azurerm_resource_group.rg.name
      tags           = azurerm_resource_group.rg.tags
      resource_token = local.resource_token
    
      # Free tier option
      sku_name     = "B_Standard_B1ms"
      storage_mb   = 32768
      storage_tier = "P4"
    
      db_names = ["BeSportSmart_Core", "BeSportSmart_Identity"]
    }` 

### App Service Plan

    `module "app_service_plan" {
      source   = "../../../modules/azure/app_service_plan"
      location = var.apps_location
      rg_name  = azurerm_resource_group.rg.name
      tags     = azurerm_resource_group.rg.tags
    
      # Free tier option
      sku_name       = "F1"
      resource_token = local.resource_token
    }` 

### Front-end App Service

    `module "frontend_app" {
      source         = "../../../modules/azure/app_service_node"
      location       = var.apps_location
      rg_name        = azurerm_resource_group.rg.name
      resource_token = local.resource_token
      always_on      = false
    
      tags               = merge(local.tags, { azd-service-name : "frontend" })
      service_name       = "frontend"
      appservice_plan_id = module.app_service_plan.APPSERVICE_PLAN_ID
      use_32_bit_worker  = true
    
      app_settings = {
        "SCM_DO_BUILD_DURING_DEPLOYMENT" = "False"
        "ENABLE_ORYX_BUILD"              = "True"
      }
    
      identity_type = "SystemAssigned"
    }` 

### Back-end App Service

    `module "backend_app" {
      source         = "../../../modules/azure/app_service_dotnet"
      location       = var.apps_location
      rg_name        = azurerm_resource_group.rg.name
      resource_token = local.resource_token
      always_on      = false
    
      tags               = merge(local.tags, { "azd-service-name" : "backend" })
      service_name       = "backend"
      appservice_plan_id = module.app_service_plan.APPSERVICE_PLAN_ID
      use_32_bit_worker  = true
    
      app_settings = {
        "SCM_DO_BUILD_DURING_DEPLOYMENT"        = "False"
        "ENABLE_ORYX_BUILD"                     = "True"
        "AZURE_KEY_VAULT_ENDPOINT"              = module.key_vault.AZURE_KEY_VAULT_ENDPOINT
        "APPLICATIONINSIGHTS_CONNECTION_STRING" = module.application_insights.APPLICATIONINSIGHTS_CONNECTION_STRING
        "API_ALLOW_ORIGINS"                     = module.frontend_app.URI
      }
    
      identity_type = "SystemAssigned"
    }` 

### Source Control and Deployment

    `module "backend_app_source_control" {
      source              = "../../../modules/azure/app_service_source_control"
      rg_name             = azurerm_resource_group.rg.name
      organization        = "vosaba"
      repository          = "be-sport-smart-backend"
      branch              = "main"
      app_identity        = module.backend_app.ID
      app_deploy_identity = module.web_app_deployment_identity.identity_id
    }
    
    module "frontend_app_source_control" {
      source              = "../../../modules/azure/app_service_source_control"
      rg_name             = azurerm_resource_group.rg.name
      organization        = "vosaba"
      repository          = "be-sport-smart-frontend"
      branch              = "main"
      app_identity        = module.frontend_app.ID
      app_deploy_identity = module.web_app_deployment_identity.identity_id
    }` 

## Comprehensive Infrastructure

This infrastructure is designed to be comprehensive and fully automated, ensuring that no manual actions are needed on the Azure portal after provisioning. Key features include:

-   **Automatic Credential Deployment**: All credentials are securely stored in Azure Key Vault and automatically configured in the applications.
-   **Federated Authentication**: Each application is configured with an identity to support federated authentication for deployment.

## CI/CD Pipelines

This repository includes GitHub Actions workflows for continuous integration and continuous deployment.

### Continuous Integration (CI)

The CI pipeline (`.github/workflows/ci.yml`) runs the following steps:

1.  Validates the Terraform configuration.
2.  Plans the Terraform deployment and prints the Terraform plan.

### Continuous Deployment (CD)

The CD pipeline (`.github/workflows/cd.yml`) runs the following steps:

1.  After manual approval, deploys the infrastructure to Azure as per the Terraform configuration.
2.  Integrates the deployed applications with their respective GitHub repositories.

## Contributions

Feel free to submit issues and pull requests. For major changes, please discuss them in an issue first to ensure your change aligns with the project goals.