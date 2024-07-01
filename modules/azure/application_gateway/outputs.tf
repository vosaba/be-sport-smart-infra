output "appgw_id" {
  value = azurerm_application_gateway.appgw.id
  description = "The ID of the Application Gateway."
}

output "appgw_public_ip" {
  value = azurerm_public_ip.appgw_public_ip.ip_address
  description = "The public IP address of the Application Gateway."
}

output "appgw_public_ip_fqdn" {
  value = azurerm_public_ip.appgw_public_ip.fqdn
  description = "The FQDN of the public IP address of the Application Gateway."
}
