variable "environment" {
  description = "Environment name"
  type        = string
}

variable "rg_location" {
  description = "Azure region where the resource group should be created"
  type        = string
}

variable "la_rg_name" {
  description = "Name of the Leonid Abasov resource group"
  type        = string
}

variable "la_arc_name" {
  description = "Name of the Leonid Abasov container registry"
  type        = string
}

variable "bss_name_prefix" {
  description = "Name prefix used for Be Sport Smart resources"
  type        = string
}