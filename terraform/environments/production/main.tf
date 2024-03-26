module "la_resource_group" {
  source      = "../../modules/resource_group"
  location    = var.rg_location
  name        = var.la_rg_name
  environment = var.environment
}

module "bss_resource_group" {
  source      = "../../modules/resource_group"
  location    = var.rg_location
  name        = var.bss_name_prefix
  environment = var.environment
}

module "bss_virtual_network" {
  source      = "../../modules/virtual_network"
  rg_name     = module.bss_resource_group.rg_name
  location    = module.bss_resource_group.rg_location
  name        = var.bss_name_prefix
  environment = var.environment

  subnets     = {
    aks-subnet = {
      name           = "aks-subnet"
      address_prefix = "10.0.1.0/24"
    },
    appgw-subnet = {
      name           = "appgw-subnet"
      address_prefix = "10.0.2.0/24"
    }
  }
}

module "bss_k8s" {
  source                     = "../../modules/aks"
  rg_id                      = module.bss_resource_group.rg_id
  rg_name                    = module.bss_resource_group.rg_name
  location                   = module.bss_resource_group.rg_location
  name                       = var.bss_name_prefix
  vnet_subnet_id             = module.bss_virtual_network.subnets_details["aks-subnet"].id
  vm_size                    = "Standard_B2als_v2"
  key_vault_secrets_provider = true
  appgw_id                   = module.bss_appgw.appgw_id
  environment                = var.environment
}

module "la_acr" {
  source      = "../../modules/container_registry"
  rg_name     = module.la_resource_group.rg_name
  location    = module.la_resource_group.rg_location
  name        = var.la_arc_name
  environment = var.environment

  kubelet_identities = {
    bss_k8s = {
      id = module.bss_k8s.kubelet_identity
    }
  }
}

module "bss_key_vault" {
  source      = "../../modules/key_vault"
  rg_name     = module.bss_resource_group.rg_name
  location    = module.bss_resource_group.rg_location
  name        = var.bss_name_prefix
  environment = var.environment

  kubelet_identities = [ module.bss_k8s.kubelet_identity ]
}

module "bss_appgw" {
  source               = "../../modules/application_gateway"
  rg_name              = module.bss_resource_group.rg_name
  location             = module.bss_resource_group.rg_location
  appgw_name           = var.bss_name_prefix
  public_ip_name       = var.bss_name_prefix
  virtual_network_name = module.bss_virtual_network.vn_name
  subnet_name          = "appgw-subnet"
  subnet_id            = module.bss_virtual_network.subnets_details["appgw-subnet"].id
  environment          = var.environment
}