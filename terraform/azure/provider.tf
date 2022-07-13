provider "azurerm" {
  subscription_id = var.subscription_id
  version = "~> 3.0.0"
  features {}
}

data "azurerm_client_config" "current" {}

terraform {
  backend "azurerm" {
  }
}
