variable "environment" {
  description = "Environment name"
  type        = string
}

variable "rg_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Resource group region"
  type        = string
}

variable "public_ip_name" {
  description = "The name of the public IP resource."
  type        = string
}

variable "public_ip_sku_name" {
  description = "The name of the SKU for the public IP."
  type        = string
  default     = "Standard"
}