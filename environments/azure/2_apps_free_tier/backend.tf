provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  skip_provider_registration = true
}

terraform {
  required_version = ">= 1.1.7, < 2.0.0"

  required_providers {
    azurerm = {
      version = "~> 3.109.0"
      source  = "hashicorp/azurerm"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~> 1.2.28"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.0"
    }
  }

  backend "azurerm" {
    resource_group_name   = "common-rg"
    storage_account_name  = "abasovcommonstorage"
    container_name        = "terraform-state-container"
    key                   = "2_apps_free_tier.terraform.tfstate"
  }
}

data "azurerm_client_config" "current" {}
