terraform {
  backend "azurerm" {
    resource_group_name   = var.infra_base_resource_group_name
    storage_account_name  = "saterraformbackendtfm"
    container_name        = "tfstate"
    key                   = "azureops-platform.terraform.tfstate"
  }
}
