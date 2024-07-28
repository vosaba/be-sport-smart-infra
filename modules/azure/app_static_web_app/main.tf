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

resource "azurerm_static_web_app" "web" {
  name                = "${var.service_name}-${var.resource_token}"
  location            = var.location
  resource_group_name = var.rg_name
  sku_tier            = "Free"
  tags                = var.tags

  # identity {
  #   type = var.identity_type
  # }
}