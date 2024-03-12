resource "azurerm_container_registry" "acr" {
  name                = "${var.name}arc"
  resource_group_name = var.rg_name
  location            = var.location
  sku                 = var.sku
}

resource "azurerm_role_assignment" "ara" {
  for_each                         = var.kubelet_identities
  principal_id                     = each.value.id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}