module "la_resource_group" {
  source      = "../../modules/resource_group"
  location    = var.rg_location
  name        = var.la_rg_name
  environment = var.environment
}

module "bss_resource_group" {
  source      = "../../modules/resource_group"
  location    = var.rg_location
  name        = var.bss_rg_name
  environment = var.environment
}

module "bss_virtual_network" {
  source      = "../../modules/virtual_network"
  rg_name     = module.bss_resource_group.rg_name
  location    = module.bss_resource_group.rg_location
  name        = var.bss_vn_name
  environment = var.environment
  subnets     = {
    aks-subnet = {
      name           = "aks-subnet"
      address_prefix = "10.0.1.0/24"
    }
  }
}

module "bss_k8s" {
  source         = "../../modules/aks"
  rg_id          = module.bss_resource_group.rg_id
  rg_name        = module.bss_resource_group.rg_name
  location       = module.bss_resource_group.rg_location
  name           = var.bss_k8s_name
  vnet_subnet_id = module.bss_virtual_network.subnets_details["aks-subnet"].id
  environment    = var.environment
}

module "la_acr" {
  source   = "../../modules/container_registry"
  rg_name  = module.la_resource_group.rg_name
  location = module.la_resource_group.rg_location
  name     = var.la_arc_name
  kubelet_identities = {
    bss_k8s = {
      id = module.bss_k8s.kubelet_identity
    }
  }
}
