module "bss_resource_group" {
  source   = "../../modules/resource_group"
  name     = var.bss_rg_name
  location = var.rg_location
}