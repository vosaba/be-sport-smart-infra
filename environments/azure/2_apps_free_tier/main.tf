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
  sku_name       = "B_Standard_B1ms"
  storage_mb     = 32768
  storage_tier   = "P4"

  db_names       = ["BeSportSmart_Core", "BeSportSmart_Identity"]
}

# ------------------------------------------------------------------------------------------------------
# Deploy app service plan
# ------------------------------------------------------------------------------------------------------
module "app_service_plan" {
  source         = "../../../modules/azure/app_service_plan"
  location       = var.apps_location
  rg_name        = azurerm_resource_group.rg.name
  tags           = azurerm_resource_group.rg.tags

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
  identity = [{
    type = "SystemAssigned"
  }]
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
# Deploy publishing profile for backend app and store it in key vault
# ------------------------------------------------------------------------------------------------------
resource "null_resource" "get_publishing_profile" {
  provisioner "local-exec" {
    command = <<EOT
    az webapp deployment list-publishing-profiles --name ${module.backend_app.APPSERVICE_NAME} --resource-group ${azurerm_resource_group.rg.name} --output json > publishProfile.json
    az keyvault secret set --vault-name ${module.key_vault.NAME} --name "${module.backend_app.APPSERVICE_NAME}-publish-profile" --file publishProfile.json
    EOT
  }
  depends_on = [module.backend_app, module.key_vault]
}
