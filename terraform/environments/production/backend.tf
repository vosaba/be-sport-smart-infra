provider "azurerm" {
  features {}
  skip_provider_registration = true
}

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.94.0"
    }
  }

  backend "azurerm" {
    resource_group_name   = "common-resource-group"
    storage_account_name  = "abasovstorage"
    container_name        = "common-blob"
    key                   = "production.terraform.tfstate"
  }
}
