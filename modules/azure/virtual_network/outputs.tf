output "vn_id" {
  value = azurerm_virtual_network.vn.id
}

output "vn_name" {
  value = azurerm_virtual_network.vn.name
}

output "vn_address_space" {
  value = azurerm_virtual_network.vn.address_space 
}

output "subnets_details" {
  value = { for sn_key, sn in azurerm_subnet.sn : sn_key => {
      id                = sn.id
      name              = sn.name
      address_prefixes  = sn.address_prefixes
    }
  }
}