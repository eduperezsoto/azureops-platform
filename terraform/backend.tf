terraform {
  backend "azurerm" {
    resource_group_name   = "rg-infra-base"
    storage_account_name  = "saterraformbackendtfm"
    container_name        = "tfstate"
    key                   = "azureops-platform.terraform.tfstate"
  }
}
