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

resource "azurecaf_name" "identity_name" {
  name          = var.identity_name
  resource_type = "azurerm_user_assigned_identity"
  random_length = 0
  clean_input   = true
}

resource "azurerm_user_assigned_identity" "identity" {
  name                = azurecaf_name.identity_name.result
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_role_assignment" "identity_role_assignment" {
  count                = length(var.role_assignments)
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
  role_definition_name = var.role_assignments[count.index].role_definition_name
  scope                = var.role_assignments[count.index].scope
}
