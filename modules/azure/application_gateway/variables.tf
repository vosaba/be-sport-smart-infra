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

variable "appgw_name" {
  description = "The name of the Application Gateway."
  type        = string
}

variable "public_ip_name" {
  description = "The name of the public IP resource."
  type        = string
}

variable "virtual_network_name" {
  description = "The name of the virtual network where the Application Gateway will be deployed."
  type        = string
}

variable "aks_name" {
  description = "The name of the AKS cluster."
  type        = string
  default     = ""
}

variable "subnet_name" {
  description = "The name of the subnet where the Application Gateway will be deployed"
  type        = string
}

variable "virtual_network_id" {
  description = "Virtual network id to assign contribution role to AKS service principal"
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet where the Application Gateway will be deployed."
  type        = string
}

variable "public_ip_sku_name" {
  description = "The name of the SKU for the public IP."
  type        = string
  default     = "Standard"
}

variable "sku_name" {
  description = "The name of the SKU for the Application Gateway."
  type        = string
  default     = "Standard_v2"
}

variable "sku_tier" {
  description = "The tier of the SKU for the Application Gateway."
  type        = string
  default     = "Standard_v2"
}

variable "sku_capacity" {
  description = "The capacity (instance count) of the SKU for the Application Gateway."
  default     = 2
}