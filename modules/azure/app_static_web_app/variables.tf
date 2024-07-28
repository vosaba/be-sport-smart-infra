variable "location" {
  description = "The supported Azure location where the resource deployed"
  type        = string
}

variable "rg_name" {
  description = "The name of the resource group to deploy resources into"
  type        = string
}

variable "service_name" {
  description = "A name to reflect the type of the static web app service e.g: frontend."
  type        = string
}

variable "identity_type" {
  description = "Specifies the type of Managed Service Identity that should be configured on this Static Web App."
  type        = string
  default     = "SystemAssigned"
}

variable "tags" {
  description = "A list of tags used for deployed services."
  type        = map(string)
}

variable "resource_token" {
  description = "A suffix string to centrally mitigate resource name collisions."
  type        = string
}
