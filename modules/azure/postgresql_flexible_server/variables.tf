variable "resource_token" {
  description = "A unique token for resource names"
  type        = string
}

variable "location" {
  description = "The location of the resources"
  type        = string
}

variable "rg_name" {
  description = "The name of the resource group"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "db_names" {
  description = "List of database names to create"
  type        = list(string)
}

variable "sku_name" {
  description = "The SKU for the plan."
  type        = string
  default     = "B1MS"
}

variable "pg_version" {
  description = "The version of PostgreSQL to deploy"
  type        = string
  default     = "13"
}

variable "storage_mb" {
  description = "The storage capacity in megabytes"
  type        = number
  default     = 32768
}

variable "storage_tier" {
  description = "The storage tier"
  type        = string
  default     = "P4"
}