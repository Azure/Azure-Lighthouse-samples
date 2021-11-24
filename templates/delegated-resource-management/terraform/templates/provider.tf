#
# Providers Configuration
#

terraform {
  required_version = "~> 0.12"
  required_providers {
    local   = "~> 1.4"
    azurerm = "~> 2.9.0"
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}