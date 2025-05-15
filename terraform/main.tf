terraform {
  required_providers { azurerm = { source = "hashicorp/azurerm" } }
  required_version = ">= 1.0"

  backend "azurerm" {
    resource_group_name  = "rg-devsecops"
    storage_account_name = "stdevsecopstfstate"
    container_name       = "tfstate"
    key                  = "simple-flask-app.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

resource "azurerm_app_service_plan" "plan" {
  name                = "${var.prefix}-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku {
    tier = "Basic"       # Nivel de servicio
    size = "B1"          # Tamaño
  }

  # configura el tipo de sistema operativo
  kind = "Linux"        # o "Windows"
}

resource "azurerm_app_service" "app" {
  name                = var.app_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.plan.id

  site_config {
    python_version = "3.10"
  }

  app_settings = {
    "KEY_VAULT_URI"           = azurerm_key_vault.kv.vault_uri
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }
}

resource "azurerm_key_vault" "kv" {
  name                        = "${var.prefix}-kv"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false
}

resource "azurerm_key_vault_secret" "secret" {
  name         = "MY_SECRET"
  value        = var.my_secret_value
  key_vault_id = azurerm_key_vault.kv.id
}
