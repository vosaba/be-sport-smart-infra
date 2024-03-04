resource "azurerm_virtual_network" "vn" {
  name                = "${var.name}-vn"
  resource_group_name = var.rg_name
  location            = var.location
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = var.environment
  }
}

resource "azurerm_subnet" "sn" {
  for_each = var.subnets
  name                 = "${each.value.name}-sn"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vn.name
  address_prefixes     = [each.value.address_prefix]
}

  # delegation {
  #   name = "delegation"

  #   service_delegation {
  #     name    = "Microsoft.ContainerInstance/containerGroups"
  #     actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
  #   }
  # }