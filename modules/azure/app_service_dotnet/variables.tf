variable "location" {
  description = "The supported Azure location where the resource deployed"
  type        = string
}

variable "rg_name" {
  description = "The name of the resource group to deploy resources into"
  type        = string
}

variable "appservice_plan_id" {
  description = "The id of the appservice plan to use."
  type        = string
}

variable "service_name" {
  description = "A name to reflect the type of the app service e.g: web, api."
  type        = string
}

variable "app_settings" {
  description = "A list of app settings pairs to be assigned to the app service"
  type        = map(string)
}

variable "identity_type" {
  description = "Specifies the type of Managed Service Identity that should be configured on this Linux Web App."
  type        = string
  default     = "SystemAssigned"
}

variable "user_assigned_identity_ids" {
  description = "A list of User Assigned Managed Identity IDs to be assigned to this Linux Web App."
  type        = list(string)
  default     = []
}

variable "app_command_line" {
  description = "The cmd line to configure the app to run."
  type        = string
  default     = ""
}

variable "tags" {
  description = "A list of tags used for deployed services."
  type        = map(string)
}

variable "resource_token" {
  description = "A suffix string to centrally mitigate resource name collisions."
  type        = string
}

variable "dotnet_version" {
  description = "the application stack dotnet version to set for the app service."
  type        = string
  default     = "8.0"
}

variable "always_on" {
  description = "The always on setting for the app service."
  type        = bool
  default     = true
}

variable "use_32_bit_worker" {
  description = "The use 32 bit worker setting for the app service."
  type        = bool
  default     = false
}

variable "health_check_path" {
  description = "The path to the health check endpoint"
  type        = string
  default     = ""
}
