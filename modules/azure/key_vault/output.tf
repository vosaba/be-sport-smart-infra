output "AZURE_KEY_VAULT_ENDPOINT" {
  value     = azurerm_key_vault.kv.vault_uri
  sensitive = true
}

output "NAME" {
  value = azurerm_key_vault.kv.name
}