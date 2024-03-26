variable "environment" {
  description = "Environment name"
  type        = string
}

variable "rg_id" {
  description = "Id of the resource group"
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

variable "name" {
  description = "Name of the AKS"
  type        = string
}

variable "k8s_version" {
  description = "Version of k8s"
  type        = string
  default     = "1.29.0"
}

variable "sku_tier" {
  description = "SKU tier"
  type        = string
  default     = "Free"
}

variable "node_count" {
  description = "Node count"
  type        = number
  default     = 1
}

variable "username" {
  description = "User name for linux profile"
  type        = string
  default     = "abasov"
}

variable "vm_size" {
  description = "VM size"
  type        = string
  default     = "Standard_D2_v2"
}

variable "vnet_subnet_id" {
  description = "Subnet where the k8s Node Pool should exist"
  type        = string
}

variable "key_vault_secrets_provider" {
  description = "Enable key vault secret provider"
  type        = bool
  default     = false
}

variable "appgw_id" {
  description = "Id of application gateway"
  type        = string
  default     = ""
}

# variable "container_registry_id" {
#   description = "Id of container registtry to assign pull role"
#   type        = string
# }
