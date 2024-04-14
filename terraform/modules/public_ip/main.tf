resource "azurerm_public_ip" "public_ip" {
  location            = var.location
  resource_group_name = var.rg_name
  name                = "${var.public_ip_name}-ip"
  allocation_method   = "Static"
  sku                 = var.public_ip_sku_name
  #zones               = [1, 2, 3]

  tags = {
    environment = var.environment
  }
}
