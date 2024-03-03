resource "azurerm_virtual_network" "vn" {
  name                = "${var.name}-vn"
  resource_group_name = var.rg_name
  location            = var.location
  address_space       = ["10.0.0.0/16"]


  dynamic "subnet" {
    for_each = var.subnets
    content {
      name           = subnet.value.name
      address_prefix = subnet.value.address_prefix
    }
  }

  tags = {
    environment = var.environment
  }
}