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

variable "name" {
  description = "Name of the Key Vault"
  type        = string
}

variable "sku" {
  description = "Sku"
  type        = string
  default    = "standard"
}

variable "kubelet_identities" {
  type = list(string)
  default = [ ]
  description = "List of kubelet identities to assign permissions"
}