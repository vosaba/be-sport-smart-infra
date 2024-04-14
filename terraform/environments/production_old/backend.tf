provider "azurerm" {
  features {}
  skip_provider_registration = true
}


terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.94.0"
    }
    azapi = {
      source = "azure/azapi"
      version = "~> 1.12.0"
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
    key                   = "production.terraform.tfstate"
  }
}
