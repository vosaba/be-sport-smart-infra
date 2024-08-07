terraform {
  required_providers {
    azurerm = {
      version = "~>3.109.0"
      source  = "hashicorp/azurerm"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~>1.2.28"
    }
  }
}

resource "azurecaf_name" "db_flexible_name" {
  name          = var.resource_token
  resource_type = "azurerm_postgresql_flexible_server"
  random_length = 0
  clean_input   = true
}

resource "random_string" "username" {
  length  = 16
  special = false
}

resource "random_password" "password" {
  length = 16
}

resource "azurerm_postgresql_flexible_server" "postgres_flexible_server" {
  name                = azurecaf_name.db_flexible_name.result
  location            = var.location
  resource_group_name = var.rg_name

  sku_name     = var.sku_name
  storage_mb   = var.storage_mb
  storage_tier = var.storage_tier

  version                = var.pg_version
  administrator_login    = random_string.username.result
  administrator_password = random_password.password.result

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  zone                         = 1

  tags = var.tags
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_access" {
  count            = var.allow_azure_access ? 1 : 0
  name             = "allow-access-from-azure-services"
  server_id        = azurerm_postgresql_flexible_server.postgres_flexible_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allowed_ips" {
  count            = length(var.allowed_ip_list)
  name             = "allowed_ip_${count.index}"
  server_id        = azurerm_postgresql_flexible_server.postgres_flexible_server.id
  start_ip_address = var.allowed_ip_list[count.index]
  end_ip_address   = var.allowed_ip_list[count.index]
}

resource "azurerm_postgresql_flexible_server_database" "example" {
  for_each  = toset(var.db_names)
  name      = each.value
  server_id = azurerm_postgresql_flexible_server.postgres_flexible_server.id
  collation = "en_US.utf8"
  charset   = "utf8"

  lifecycle {
    prevent_destroy = true
  }
}
