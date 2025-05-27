terraform {
  backend "azurerm" {
    resource_group_name   = "rg-terraform-backend"
    storage_account_name  = "saterraformstatetfm"
    container_name        = "tfstate"
    key                   = "azureops-platform.terraform.tfstate"
  }
}
