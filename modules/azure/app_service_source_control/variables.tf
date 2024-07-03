variable "rg_name" {
  description = "The name of the resource group."
  type        = string
}

variable "organization" {
  description = "The GitHub organization name."
  type        = string
}

variable "repository" {
  description = "The GitHub repository name."
  type        = string
}

variable "branch" {
  description = "The GitHub branch name."
  type        = string
}

variable "app_identity" {
  description = "The app service identity."
  type        = string
}

variable "app_deploy_identity" {
  description = "The app service deploy identity."
  type        = string
}

variable "entity" {
  description = "The entity type (e.g., environment)."
  type        = string
  default     = "environment"
}

variable "entity_value" {
  description = "The entity value (e.g., production)."
  type        = string
  default     = "production"
}