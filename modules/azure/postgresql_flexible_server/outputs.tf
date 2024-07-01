output "AZURE_PG_FQDN" {
  value     = azurerm_postgresql_flexible_server.postgres_flexible_server.fqdn
  sensitive = true
}

output "AZURE_PG_NAME" {
  value     = azurerm_postgresql_flexible_server.postgres_flexible_server.name
  sensitive = false
}

output "AZURE_PG_USERNAME" {
  value     = random_string.username.result
  sensitive = true
}

output "AZURE_PG_PASSWORD" {
  value     = random_password.password.result
  sensitive = true
}