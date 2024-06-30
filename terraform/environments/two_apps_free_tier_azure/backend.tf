provider "azurerm" {
  features {}
  skip_provider_registration = true
}

terraform {
  required_version = ">= 1.1.7, < 2.0.0"

  required_providers {
    azurerm = {
      version = "~>3.97.1"
      source  = "hashicorp/azurerm"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~>1.2.24"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name   = "common-resource-group"
    storage_account_name  = "abasovstorage"
    container_name        = "common-blob"
    key                   = "two_app_free.terraform.tfstate"
  }
}

data "azurerm_client_config" "current" {}