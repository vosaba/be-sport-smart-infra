output "ID" {
  value = azurerm_static_site.web.id
}

output "default_hostname" {
  value = azurerm_static_site.web.default_host_name
}

output "IDENTITY_PRINCIPAL_ID" {
  value     = length(azurerm_static_site.web.identity) == 0 ? "" : azurerm_static_site.web.identity.0.principal_id
  sensitive = true
}

output "API_KEY" {
  value     = azurerm_static_site.web.api_key
  sensitive = true
}

output "APPSERVICE_NAME" {
  value = azurerm_static_site.web.name
}
