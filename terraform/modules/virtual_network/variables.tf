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
  description = "Name of virtual network"
  type        = string
}

variable "subnets" {
  description = "A map of subnets to be created"
  type = map(object({
    name           = string
    address_prefix = string
  }))
  default = {}
}

# variable "container_registry_id" {
#   description = "Id of container registtry to assign pull role"
#   type        = string
# }
