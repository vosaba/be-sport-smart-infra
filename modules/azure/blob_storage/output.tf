output "storage_account_name" {
  value = azurerm_storage_account.storage_account.name
}

output "storage_account_key" {
  value = azurerm_storage_account.storage_account.primary_access_key
}

output "blob_container_name" {
  value = azurerm_storage_container.blob_container.name
}

output "blob_container_url" {
  value = azurerm_storage_container.blob_container.url
}