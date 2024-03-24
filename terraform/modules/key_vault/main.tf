data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                          = "${var.name}-kv"
  location                      = var.location
  resource_group_name           = var.rg_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = var.sku
  public_network_access_enabled = false
  tags = {
    environment = var.environment
  }
}

# Add access for administrators
# resource "azurerm_key_vault_access_policy" "example" {
#   key_vault_id = azurerm_key_vault.kv.id
#   tenant_id    = data.azurerm_client_config.current.tenant_id
#   object_id    = data.azurerm_client_config.current.object_id

#   key_permissions = [
#     "Get",
#   ]

#   secret_permissions = [
#     "Get",
#   ]
# }

resource "azurerm_key_vault_access_policy" "akvap" {
  for_each     = toset(var.kubelet_identities)
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = each.value

  key_permissions = [
    "Get", "List"
  ]

  secret_permissions = [
    "Get", "List"
  ]
}