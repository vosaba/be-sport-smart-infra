terraform {
  required_providers {
    azurerm = {
      version = "~>3.97.1"
      source  = "hashicorp/azurerm"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~>1.2.24"
    }
  }
}

resource "azurecaf_name" "db_acc_name" {
  name          = var.resource_token
  resource_type = "azurerm_postgresql_server"
  random_length = 0
  clean_input   = true
}

resource "random_string" "username" {
  length = 16
  special = false
}

resource "random_password" "password" {
  length = 16
}

resource "azurerm_postgresql_server" "postgresserver" {
  name                = azurecaf_name.db_acc_name.result
  location            = var.location
  resource_group_name = var.rg_name
 
  sku_name = "B_Gen5_2"
 
  storage_mb                       = 5120
  backup_retention_days            = 7
  geo_redundant_backup_enabled     = false
  auto_grow_enabled                = true
 
  administrator_login              = random_string.username.result
  administrator_login_password     = random_password.password.result
  version                          = "9.5"
  ssl_enforcement_enabled          = false
  ssl_minimal_tls_version_enforced = "TLSEnforcementDisabled"

  tags                             = var.tags
}

resource "azurerm_postgresql_database" "db" {
  for_each            = toset(var.db_names)
  name                = each.value
  resource_group_name = var.rg_name
  server_name         = azurerm_postgresql_server.postgresserver.name
  charset             = "UTF8"
  collation           = "en-GB"
}