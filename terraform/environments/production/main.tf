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
}