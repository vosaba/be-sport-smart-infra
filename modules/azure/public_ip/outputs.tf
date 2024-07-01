output "public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
  description = "The public IP address of the Application Gateway."
}

output "public_ip_fqdn" {
  value = azurerm_public_ip.public_ip.fqdn
  description = "The FQDN of the public IP address of the Application Gateway."
}
