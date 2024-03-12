variable "rg_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Resource group region"
  type        = string
}

variable "name" {
  description = "Name of the acr"
  type        = string
}

variable "sku" {
  description = "Sku"
  type        = string
  default    = "Basic"
}

variable "kubelet_identities" {
  description = "A map of k8s identity to add pull permission"
  type = map(object({
    id = string
  }))
  default = {}
}