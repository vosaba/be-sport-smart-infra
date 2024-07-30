resource "random_id" "backend_app_admin_username" {
  byte_length = 8
  prefix      = "admin-"
}

resource "random_password" "backend_app_admin_password" {
  length  = 16
  special = true
  upper   = true
  lower   = true
}

locals {
  tags               = { env-name : var.environment }
  sha                = base64encode(sha256("${var.environment}${var.location}${data.azurerm_client_config.current.subscription_id}"))
  resource_token     = var.bss_name_prefix
  pg_username_key    = "AZURE-PG-USERNAME"
  pg_password_key    = "AZURE-PG-PASSWORD"
  core_db_name       = "BeSportSmart_Core"
  identity_db_name   = "BeSportSmart_Identity"
  pg_allowed_ip_list = ["76.31.141.141"]

  frontend_static_app_token_vault_key = "FRONTEND-STATIC-WEB-APPS-API-TOKEN"
  frontend_static_app_uri             = "https://besportsmart.com"
  frontend_static_app_repository      = "be-sport-smart-frontend"

  frontend_workflow_token_key                                 = "STATIC_WEB_APPS_API_TOKEN"
  frontend_workflow_backend_base_url_key                      = "BACKEND_BASE_URL"
  frontend_workflow_dynamic_localization_base_url_key         = "DYNAMIC_LOCALIZATION_BASE_URL"
  frontend_workflow_applicationinsights_connection_string_key = "APPLICATIONINSIGHTS_CONNECTION_STRING"

  github_token_key = "KEY_GITHUB_TOKEN"

  backend_app_admin_username_key = "BSS-BACKEND-APP-ADMIN-USERNAME"
  backend_app_admin_username     = random_id.backend_app_admin_username.hex
  backend_app_admin_email_key    = "BSS-BACKEND-APP-ADMIN-USERNAME"
  backend_app_admin_email        = "${random_id.backend_app_admin_username.hex}@example.com"
  backend_app_admin_password_key = "BSS-BACKEND-APP-ADMIN-PASSWORD"
  backend_app_admin_password     = random_password.backend_app_admin_password.result

  backend_app_command_line = "dotnet /home/site/wwwroot/Bss.Bootstrap.dll"
}

# ------------------------------------------------------------------------------------------------------
# Deploy resource Group
# ------------------------------------------------------------------------------------------------------
resource "azurecaf_name" "rg_name" {
  name          = var.environment
  resource_type = "azurerm_resource_group"
  random_length = 0
  clean_input   = true
}

resource "azurerm_resource_group" "rg" {
  name     = azurecaf_name.rg_name.result
  location = var.location

  tags = local.tags
}

# ------------------------------------------------------------------------------------------------------
# Deploy application insights
# ------------------------------------------------------------------------------------------------------
module "application_insights" {
  source           = "../../../modules/azure/application_insights"
  location         = var.location
  rg_name          = azurerm_resource_group.rg.name
  environment_name = var.environment
  workspace_id     = module.log_analytics.LOGANALYTICS_WORKSPACE_ID
  tags             = azurerm_resource_group.rg.tags
  resource_token   = local.resource_token
}

# ------------------------------------------------------------------------------------------------------
# Deploy log analytics
# ------------------------------------------------------------------------------------------------------
module "log_analytics" {
  source         = "../../../modules/azure/log_analytics"
  location       = var.location
  rg_name        = azurerm_resource_group.rg.name
  tags           = azurerm_resource_group.rg.tags
  resource_token = local.resource_token
}

# ------------------------------------------------------------------------------------------------------
# Deploy key vault
# ------------------------------------------------------------------------------------------------------
module "key_vault" {
  source                   = "../../../modules/azure/key_vault"
  location                 = var.location
  principal_id             = data.azurerm_client_config.current.object_id
  rg_name                  = azurerm_resource_group.rg.name
  tags                     = azurerm_resource_group.rg.tags
  resource_token           = local.resource_token
  access_policy_object_ids = [module.backend_app.IDENTITY_PRINCIPAL_ID]
  secrets = [
    {
      name  = local.pg_username_key
      value = module.postgresql_flexible_server.AZURE_PG_USERNAME
    },
    {
      name  = local.pg_password_key
      value = module.postgresql_flexible_server.AZURE_PG_PASSWORD
    },
    {
      name  = local.backend_app_admin_username_key
      value = local.backend_app_admin_username
    },
    {
      name  = local.backend_app_admin_email_key
      value = local.backend_app_admin_email
    },
    {
      name  = local.backend_app_admin_password_key
      value = local.backend_app_admin_password
    },
    {
      name  = local.frontend_static_app_token_vault_key
      value = module.frontend_static_app.API_KEY
    }
  ]
}

# ------------------------------------------------------------------------------------------------------
# Deploy postgresql flexible server
# ------------------------------------------------------------------------------------------------------
module "postgresql_flexible_server" {
  source         = "../../../modules/azure/postgresql_flexible_server"
  location       = var.location
  rg_name        = azurerm_resource_group.rg.name
  tags           = azurerm_resource_group.rg.tags
  resource_token = local.resource_token

  # Free tier option
  sku_name     = "B_Standard_B1ms"
  storage_mb   = 32768
  storage_tier = "P4"

  db_names        = [local.core_db_name, local.identity_db_name]
  allowed_ip_list = local.pg_allowed_ip_list
}

# ------------------------------------------------------------------------------------------------------
# Deploy app service plan
# ------------------------------------------------------------------------------------------------------
module "app_service_plan" {
  source   = "../../../modules/azure/app_service_plan"
  location = var.apps_location
  rg_name  = azurerm_resource_group.rg.name
  tags     = azurerm_resource_group.rg.tags

  # Free tier option
  sku_name       = "F1"
  resource_token = local.resource_token
}

# ------------------------------------------------------------------------------------------------------
# Deploy front-end static web app
# ------------------------------------------------------------------------------------------------------
module "frontend_static_app" {
  source         = "../../../modules/azure/app_static_web_app"
  location       = var.location
  rg_name        = azurerm_resource_group.rg.name
  service_name   = "static-frontend"
  resource_token = local.resource_token
  tags           = merge(local.tags, { azd-service-name : "static-frontend" })
  identity_type  = "SystemAssigned"
}

# ------------------------------------------------------------------------------------------------------
# Deploy back-end app
# ------------------------------------------------------------------------------------------------------
module "backend_app" {
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

    "Security__AllowedOrigins__0"            = module.frontend_static_app.URI
    "Security__AllowedOrigins__1"            = local.frontend_static_app_uri
    "BssDal__ConnectionStrings__BssCore"     = <<-EOT
      Server=${module.postgresql_flexible_server.AZURE_PG_FQDN};
      Database=${local.core_db_name};
      Port=5432;
      User Id=${module.postgresql_flexible_server.AZURE_PG_USERNAME};
      Password=${module.postgresql_flexible_server.AZURE_PG_PASSWORD};
    EOT
    "BssDal__ConnectionStrings__BssIdentity" = <<-EOT
      Server=${module.postgresql_flexible_server.AZURE_PG_FQDN};
      Database=${local.identity_db_name};
      Port=5432;
      User Id=${module.postgresql_flexible_server.AZURE_PG_USERNAME};
      Password=${module.postgresql_flexible_server.AZURE_PG_PASSWORD};
    EOT

    "BssIdentityInitializer__SuperAdminUserName" = local.backend_app_admin_username
    "BssIdentityInitializer__SuperAdminEmail"    = local.backend_app_admin_email
    "BssIdentityInitializer__SuperAdminPassword" = local.backend_app_admin_password
  }

  identity_type = "SystemAssigned"

  app_command_line = local.backend_app_command_line
}

# ------------------------------------------------------------------------------------------------------
# Deploy blob storage
# ------------------------------------------------------------------------------------------------------
module "blob_storage" {
  source               = "../../../modules/azure/blob_storage"
  rg_name              = azurerm_resource_group.rg.name
  location             = var.location
  tags                 = local.tags
  resource_token       = local.resource_token
  container_names      = ["localization", "images"]
  cors_allowed_origins = [module.frontend_static_app.URI, local.frontend_static_app_uri]
  writer_identity_id   = module.backend_app.IDENTITY_PRINCIPAL_ID
}

# Workaround: set blob storage settings to the backend app after the blob storage is deployed
resource "null_resource" "backend_app_blob_storage_settings" {
  triggers = {
    blob_storage_account_name = module.blob_storage.storage_account_name
    blob_storage_account_key  = module.blob_storage.storage_account_key
    blob_container_names      = join(",", module.blob_storage.blob_container_names)
  }

  provisioner "local-exec" {
    command = <<EOT
      az webapp config appsettings set \
        --resource-group ${azurerm_resource_group.rg.name} \
        --name ${module.backend_app.APPSERVICE_NAME} \
        --settings BssLocalization__BlobStorage__AccountName=${module.blob_storage.storage_account_name} \
                   BssLocalization__BlobStorage__AccountKey=${module.blob_storage.storage_account_key} \
                   BssLocalization__BlobStorage__Containers=${join(",", module.blob_storage.blob_container_names)}
    EOT
  }
}

# ------------------------------------------------------------------------------------------------------
# Create User-assigned Identity for web apps deployment
# ------------------------------------------------------------------------------------------------------
module "web_app_deployment_identity" {
  source              = "../../../modules/azure/user_assigned_identity"
  identity_name       = "deployment-identity"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  role_assignments = [
    {
      role_definition_name = "Website Contributor"
      scope                = module.backend_app.ID
    }
  ]
}

# ------------------------------------------------------------------------------------------------------
# Configure source control and deployment
# ------------------------------------------------------------------------------------------------------
resource "azurerm_source_control_token" "source_token" {
  type         = "GitHub"
  token        = var.github_token
  token_secret = var.github_token
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}

# ------------------------------------------------------------------------------------------------------
# Configure source control for the backend app
# ------------------------------------------------------------------------------------------------------
module "backend_app_source_control" {
  source              = "../../../modules/azure/app_service_source_control"
  rg_name             = azurerm_resource_group.rg.name
  organization        = var.github_owner
  repository          = "be-sport-smart-backend"
  branch              = "main"
  app_identity        = module.backend_app.ID
  app_deploy_identity = module.web_app_deployment_identity.identity_id
}


# ------------------------------------------------------------------------------------------------------
# Configure secrets and variables for the frontend app repository
# ------------------------------------------------------------------------------------------------------
resource "github_actions_secret" "frontend_static_app_token_secret" {
  repository      = local.frontend_static_app_repository
  secret_name     = local.frontend_workflow_token_key
  plaintext_value = module.frontend_static_app.API_KEY
}

resource "github_actions_secret" "frontend_static_github_token_secret" {
  repository      = local.frontend_static_app_repository
  secret_name     = local. github_token_key
  plaintext_value = var.github_token
}

resource "github_actions_variable" "frontend_static_backend_base_url_variable" {
  repository    = local.frontend_static_app_repository
  variable_name = local.frontend_workflow_backend_base_url_key
  value         = module.backend_app.URI
}

resource "github_actions_variable" "frontend_static_dynamic_localization_base_url_variable" {
  repository    = local.frontend_static_app_repository
  variable_name = local.frontend_workflow_dynamic_localization_base_url_key
  value         = jsondecode(jsonencode(module.blob_storage.blob_container_urls))["localization"]
}

resource "github_actions_variable" "frontend_static_applicationinsights_connection_string_variable" {
  repository    = local.frontend_static_app_repository
  variable_name = local.frontend_workflow_applicationinsights_connection_string_key
  value         = module.application_insights.APPLICATIONINSIGHTS_CONNECTION_STRING
}

# ------------------------------------------------------------------------------------------------------
# Configure github actions for the frontend app
# ------------------------------------------------------------------------------------------------------
resource "github_repository_file" "static_web_app_deploy_workflow" {
  repository = local.frontend_static_app_repository
  branch     = "main"
  file       = ".github/workflows/deploy_app.yml"
  content = templatefile("../../../templates/deploy_static_web_app.tpl",
    {
      app_location                              = "/"
      api_location                              = ""
      output_location                           = "dist"
      github_token_key                          = local.github_token_key
      app_token_key                             = local.frontend_workflow_token_key
      backend_base_url_key                      = local.frontend_workflow_backend_base_url_key
      dynamic_localization_base_url_key         = local.frontend_workflow_dynamic_localization_base_url_key
      applicationinsights_connection_string_key = local.frontend_workflow_applicationinsights_connection_string_key
    }
  )
  commit_message      = "Modify workflow (by Terraform)"
  commit_author       = "terrafrom-ci"
  commit_email        = "terrafrom.ci@example.com"
  overwrite_on_create = true
}
