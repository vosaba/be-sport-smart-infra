terraform {
  backend "azurerm" {
    resource_group_name   = "common-resource-group"
    storage_account_name  = "abasovstorage"
    container_name        = "common-blob"
    key                   = "production.terraform.tfstate"
  }
}