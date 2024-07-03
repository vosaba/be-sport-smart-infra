variable "identity_name" {
  description = "The name of the user-assigned identity."
  type        = string
}

variable "location" {
  description = "The location where the resources will be created."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
}

variable "role_assignments" {
  description = "A list of role assignments containing role_definition_name and scope."
  type = list(object({
    role_definition_name = string
    scope                = string
  }))
}
