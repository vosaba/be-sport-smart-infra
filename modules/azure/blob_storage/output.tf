output "storage_account_name" {
  value = azurerm_storage_account.storage_account.name
}

output "storage_account_key" {
  value = azurerm_storage_account.storage_account.primary_access_key
}

output "blob_container_names" {
  value = [for container in azurerm_storage_container.blob_containers : container.name]
}

output "blob_container_urls" {
  value = [for container in azurerm_storage_container.blob_containers : "https://${azurerm_storage_account.storage_account.name}.blob.core.windows.net/${container.name}"]
}
