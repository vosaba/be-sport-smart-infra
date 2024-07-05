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

  backend_app_admin_password_key = "BSS-BACKEND-APP-ADMIN-PASSWORD"
  backend_app_admin_password     = random_password.backend_app_admin_password.result

  frontend_app_command_line = "pm2 serve /home/site/wwwroot/dist --no-daemon --spa"
  backend_app_command_line  = "dotnet /home/site/wwwroot/Bss.Bootstrap.dll"

  localization_test_file = "https://api.jsonbin.io/v3/b/667e16dbe41b4d34e40a2652"
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
      name  = local.backend_app_admin_password_key
      value = local.backend_app_admin_password
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
# Deploy front-end app
# ------------------------------------------------------------------------------------------------------
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

    "DYNAMIC_LOCALIZATION_BASE_URL"         = local.localization_test_file
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = module.application_insights.APPLICATIONINSIGHTS_CONNECTION_STRING
  }

  identity_type = "SystemAssigned"

  app_command_line = local.frontend_app_command_line
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
    "SCM_DO_BUILD_DURING_DEPLOYMENT"         = "False"
    "ENABLE_ORYX_BUILD"                      = "True"
    "AZURE_KEY_VAULT_ENDPOINT"               = module.key_vault.AZURE_KEY_VAULT_ENDPOINT
    "APPLICATIONINSIGHTS_CONNECTION_STRING"  = module.application_insights.APPLICATIONINSIGHTS_CONNECTION_STRING
    "API_ALLOW_ORIGINS"                      = module.frontend_app.URI
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

    "BssIdentityInitializer__SuperAdminPassword" = local.backend_app_admin_password
  }

  identity_type = "SystemAssigned"

  app_command_line = local.backend_app_command_line
}

# Workaround: set BACKEND_BASE_URL to the backend_app URI after both apps are deployed
resource "null_resource" "frontend_app_set_backend_url" {
  triggers = {
    web_uri = module.backend_app.URI
  }

  provisioner "local-exec" {
    command = "az webapp config appsettings set --resource-group ${azurerm_resource_group.rg.name} --name ${module.frontend_app.APPSERVICE_NAME} --settings BACKEND_BASE_URL=${module.backend_app.URI}"
  }
}

# # Workaround: set API_ALLOW_ORIGINS to the frontend_app URI
# resource "null_resource" "backend_app_set_allow_origins" {
#   triggers = {
#     web_uri = module.frontend_app.URI
#   }

#   provisioner "local-exec" {
#     command = "az webapp config appsettings set --resource-group ${azurerm_resource_group.rg.name} --name ${module.backend_app.APPSERVICE_NAME} --settings API_ALLOW_ORIGINS=${module.frontend_app.URI}"
#   }
# }

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
    },
    {
      role_definition_name = "Website Contributor"
      scope                = module.frontend_app.ID
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

module "backend_app_source_control" {
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
}
