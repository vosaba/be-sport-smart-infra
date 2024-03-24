output "kv_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.kv.name
}

output "kv_id" {
  description = "The Id of the Key Vault"
  value       = azurerm_key_vault.kv.id
}
