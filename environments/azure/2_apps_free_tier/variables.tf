variable "environment" {
  description = "Environment name"
  type        = string
}

variable "location" {
  description = "Azure region where the resource group should be created"
  type        = string
}

variable "bss_name_prefix" {
  description = "Name prefix used for Be Sport Smart resources"
  type        = string
}