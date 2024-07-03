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


resource "azurerm_app_service_source_control" "app_source_control" {
  app_id                 = var.app_identity
  repo_url               = "https://github.com/${var.organization}/${var.repository}"
  branch                 = var.branch
  use_manual_integration = true
}

resource "azurerm_federated_identity_credential" "app_federated_identity" {
  name                = "${var.organization}-${var.repository}"
  resource_group_name = var.rg_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  parent_id           = var.app_deploy_identity
  subject             = "repo:${var.organization}/${var.repository}:${var.entity}:${var.entity_value}"
}