locals {
  tags           = { env-name : var.environment }
  sha            = base64encode(sha256("${var.environment}${var.location}${data.azurerm_client_config.current.subscription_id}"))
  resource_token = var.bss_name_prefix
  # backend_app_command_line             = "gunicorn --workers 4 --threads 2 --timeout 60 --access-logfile \"-\" --error-logfile \"-\" --bind=0.0.0.0:8000 -k uvicorn.workers.UvicornWorker todo.app:app"
  pg_username = "AZURE-PG-USERNAME"
  pg_password = "AZURE-PG-PASSWORD"
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
      name  = local.pg_username
      value = module.postgresql_flexible_server.AZURE_PG_USERNAME
    },
    {
      name  = local.pg_password
      value = module.postgresql_flexible_server.AZURE_PG_PASSWORD
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

  db_names = ["BeSportSmart_Core", "BeSportSmart_Identity"]
}

# ------------------------------------------------------------------------------------------------------
# Create User-assigned Identity for web apps deployment
# ------------------------------------------------------------------------------------------------------
resource "azurecaf_name" "identity_name" {
  name          = "deployment-identity"
  resource_type = "azurerm_user_assigned_identity"
  random_length = 0
  clean_input   = true
}

resource "azurerm_user_assigned_identity" "web_app_identity" {
  name                = azurecaf_name.identity_name.result
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

# resource "azurerm_role_assignment" "identity_contributor" {
#   principal_id         = azurerm_user_assigned_identity.web_app_identity.principal_id
#   role_definition_name = "Contributor"
#   scope                = azurerm_resource_group.rg.id
# }

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
  }

  identity_type = "SystemAssigned"

  # user_assigned_identity_ids = [
  #   azurerm_user_assigned_identity.web_app_identity.id
  # ]

  app_command_line = "pm2 serve /home/site/wwwroot --no-daemon --spa"
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
    "API_ALLOW_ORIGINS"                     = module.frontend_app.URI
  }

  # app_command_line = local.backend_app_command_line
  identity_type = "SystemAssigned"

  # user_assigned_identity_ids = [
  #   azurerm_user_assigned_identity.web_app_identity.id
  # ]
}

# Workaround: set API_ALLOW_ORIGINS to the frontend_app URI
resource "null_resource" "backend_app_set_allow_origins" {
  triggers = {
    web_uri = module.frontend_app.URI
  }

  provisioner "local-exec" {
    command = "az webapp config appsettings set --resource-group ${azurerm_resource_group.rg.name} --name ${module.backend_app.APPSERVICE_NAME} --settings API_ALLOW_ORIGINS=${module.frontend_app.URI}"
  }
}

# ------------------------------------------------------------------------------------------------------
# Configure back-end app source control
# ------------------------------------------------------------------------------------------------------
resource "azurerm_app_service_source_control" "backend_app_source_control" {
  app_id                 = module.backend_app.ID
  repo_url               = "https://github.com/vosaba/be-sport-smart-backend"
  branch                 = "main"
  use_manual_integration = true

  # github_action_configuration {
  #   code_configuration {
  #     runtime_stack   = "dotnetcore"
  #     runtime_version = "8.0"
  #   }

  #   generate_workflow_file = false
  # }
}

resource "azurerm_source_control_token" "source_token" {
  type         = "GitHub"
  token        = var.github_token
  token_secret = var.github_token
}

resource "azurerm_federated_identity_credential" "example" {
  name                = "vosaba-be-sport-smart-backend"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  parent_id           = azurerm_user_assigned_identity.web_app_identity.id
  subject             = "repo:vosaba/be-sport-smart-backend:environment:production"
}