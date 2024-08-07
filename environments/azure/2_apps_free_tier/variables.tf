variable "environment" {
  description = "Environment name"
  type        = string
}

variable "location" {
  description = "Azure region where the resource group should be created"
  type        = string
}

variable "apps_location" {
  description = "Azure region where the apps should be created"
  type        = string
  
}

variable "bss_name_prefix" {
  description = "Name prefix used for Be Sport Smart resources"
  type        = string
}

variable "github_token" {
  description = "The GitHub authentication token."
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "The GitHub owner."
  type        = string
}