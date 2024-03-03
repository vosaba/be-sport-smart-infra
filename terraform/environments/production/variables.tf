variable "environment" {
  description = "Environment name"
  type        = string
}

variable "rg_location" {
  description = "Azure region where the resource group should be created"
  type        = string
}

variable "bss_rg_name" {
  description = "Name of the resource group for Be Sport Smart"
  type        = string
}

variable "bss_vn_name" {
  description = "Name of virtual network for Be Sport Smart"
}

