#
# Providers Configuration
#

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.86.0"
    }
  }
}

provider "azurerm" {
  features {}
}