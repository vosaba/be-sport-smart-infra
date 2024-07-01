variable "location" {
  description = "The supported Azure location where the resource deployed"
  type        = string
}

variable "rg_name" {
  description = "The name of the resource group to deploy resources into"
  type        = string
}

variable "tags" {
  description = "A list of tags used for deployed services."
  type        = map(string)
}

variable "resource_token" {
  description = "A suffix string to centrally mitigate resource name collisions."
  type        = string
}

variable "sku_name" {
  description = "The SKU for the plan."
  type        = string
  default     = "B1MS"
}

variable "db_names" {
  type = list(string)
  default = [ ]
  description = "List of database names to create in the PostgreSQL server"
}