resource "azurerm_public_ip" "appgw_public_ip" {
  location            = var.location
  resource_group_name = var.rg_name
  name                = "${var.public_ip_name}-ip"
  allocation_method   = "Static"
  sku                 = var.public_ip_sku_name
  zones               = local.zones

  tags = {
    environment = var.environment
  }
}

locals {
  zones                          = [1, 2, 3]
  backend_address_pool_name      = "${var.virtual_network_name}-beap"
  frontend_port_name             = "${var.virtual_network_name}-feport"
  frontend_ip_configuration_name = "${var.virtual_network_name}-feip"
  http_setting_name              = "${var.virtual_network_name}-be-htst"
  listener_name                  = "${var.virtual_network_name}-httplstn"
  request_routing_rule_name      = "${var.virtual_network_name}-rqrt"
  redirect_configuration_name    = "${var.virtual_network_name}-rdrcfg"
}

resource "azurerm_application_gateway" "appgw" {
  location            = var.location
  resource_group_name = var.rg_name
  name                = "${var.appgw_name}-appgw"
  zones               = local.zones

  sku {
    name     = var.sku_name
    tier     = var.sku_tier
    capacity = var.sku_capacity
  }

  gateway_ip_configuration {
    name      = var.subnet_name
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_port {
    name = "httpsPort"
    port = 443
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.appgw_public_ip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 1
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  tags = {
    environment = var.environment
  }
}

data "azurerm_user_assigned_identity" "identity-appgw" {
  name                = "ingressapplicationgateway-${var.aks_name}" # convention name for AGIC Identity
  resource_group_name = var.rg_name

  # depends_on = [azurerm_kubernetes_cluster.aks]
}

resource "azurerm_role_assignment" "role-contributor" {
  scope                = var.virtual_network_id #data.azurerm_resource_group.rg-vnet.id # azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = data.azurerm_user_assigned_identity.identity-appgw.principal_id

  depends_on = [azurerm_application_gateway.appgw]
}
resource "azurerm_role_assignment" "role-contributor-rg" {
  scope                = var.rg_name # azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = data.azurerm_user_assigned_identity.identity-appgw.principal_id

  depends_on = [azurerm_application_gateway.appgw]
}

# resource "azurerm_role_assignment" "aks_mi_network_contributor" {
#   scope                = var.virtual_network_id
#   role_definition_name = "Network Contributor"
#   principal_id         = azurerm_application_gateway.appgw.id

#   skip_service_principal_aad_check = true
# }