Here's the generated Markdown file for your Terraform code:

```markdown
# Terraform Configuration for Azure App Service Web App

This Terraform configuration deploys an Azure App Service Web App with specific configurations for node version, health check, app settings, identity, and logging.

## Required Providers

```hcl
terraform {
  required_providers {
    azurerm = {
      version = "~>3.109.0"
      source  = "hashicorp/azurerm"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~>1.2.28"
    }
  }
}
```

## Deploy App Service Web App

This section describes the resources needed to deploy the app service web app.

### AzureCAF Name Resource

```hcl
resource "azurecaf_name" "web_name" {
  name          = "${var.service_name}-${var.resource_token}"
  resource_type = "azurerm_app_service"
  random_length = 0
  clean_input   = true
}
```

### Azure Linux Web App Resource

```hcl
resource "azurerm_linux_web_app" "web" {
  name                = azurecaf_name.web_name.result
  location            = var.location
  resource_group_name = var.rg_name
  service_plan_id     = var.appservice_plan_id
  https_only          = true
  tags                = var.tags

  ftp_publish_basic_authentication_enabled       = true
  webdeploy_publish_basic_authentication_enabled = true

  site_config {
    always_on         = var.always_on
    use_32_bit_worker = var.use_32_bit_worker
    ftps_state        = "FtpsOnly"
    app_command_line  = var.app_command_line
    application_stack {
      node_version = var.node_version
    }
    health_check_path = var.health_check_path
  }

  app_settings = var.app_settings

  identity {
    type         = var.identity_type
    identity_ids = var.user_assigned_identity_ids
  }

  logs {
    application_logs {
      file_system_level = "Verbose"
    }
    detailed_error_messages = true
    failed_request_tracing  = true
    http_logs {
      file_system {
        retention_in_days = 1
        retention_in_mb   = 35
      }
    }
  }
}
```

#### Temporary Solution for Basic Publishing Credentials Policies

```hcl
# This is a temporary solution until the azurerm provider supports the basicPublishingCredentialsPolicies resource type
# resource "null_resource" "webapp_basic_auth_disable" {
#   triggers = {
#     account = azurerm_linux_web_app.web.name
#   }

#   provisioner "local-exec" {
#     command = "az resource update --resource-group ${var.rg_name} --name ftp --namespace Microsoft.Web --resource-type basicPublishingCredentialsPolicies --parent sites/${azurerm_linux_web_app.web.name} --set properties.allow=false && az resource update --resource-group ${var.rg_name} --name scm --namespace Microsoft.Web --resource-type basicPublishingCredentialsPolicies --parent sites/${azurerm_linux_web_app.web.name} --set properties.allow=false"
#   }
# }
```

## Usage

This section provides an example of how to use the above resources to deploy a front-end app.

### Deploy Front-End App

```hcl
module "frontend_app" {
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

    # Only 'VITE_' prefixed variables are exposed to the front-end app due to security reasons
    # "VITE_DYNAMIC_LOCALIZATION_BASE_URL"         = local.localization_test_file
    # "VITE_APPLICATIONINSIGHTS_CONNECTION_STRING" = module.application_insights.APPLICATIONINSIGHTS_CONNECTION_STRING
  }

  identity_type = "SystemAssigned"

  app_command_line = local.frontend_app_command_line
}
```

### Notes

- Ensure you have the required providers installed and properly configured.
- Customize the `app_settings` according to your application needs.
- The temporary solution for basic publishing credentials policies is commented out and can be enabled if required.
- The example module `frontend_app` showcases how to deploy a front-end app with the provided configurations.
