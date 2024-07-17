variable "resource_token" {
  description = "Resource token for naming convention"
  type        = string
}

variable "rg_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Location of the resources"
  type        = string
}

variable "tags" {
  description = "Tags for the resources"
  type        = map(string)
}

variable "container_names" {
  description = "List of container names to be created"
  type        = list(string)
}

variable "writer_identity_id" {
  description = "Principal ID for access control"
  type        = string
}
