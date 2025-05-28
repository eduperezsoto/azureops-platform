provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    Owner = var.owner_tag
  }
}

# Key Vault
resource "azurerm_key_vault" "kv" {
  name                = var.key_vault_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    secret_permissions = ["get", "list", "set", "delete"]
  }

  network_acls {
    default_action = "Deny"              # Deniega todo por defecto
    bypass         = ["AzureServices"]   # Permite sólo a servicios de Azure
  }
  
  tags = {
    Owner = var.owner_tag
  }
}

# Demo secret
resource "azurerm_key_vault_secret" "my_secret" {
  name         = "MY_SECRET"
  value        = var.my_secret_value
  key_vault_id = azurerm_key_vault.kv.id
}

# App Service Plan
resource "azurerm_app_service_plan" "plan" {
  name                = "${var.app_name}-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind = "Linux"
  reserved = true
  
  sku {
    tier = "Basic"
    size = "B1"
  }
  tags = {
    Owner = var.owner_tag
  }
}

# App Service with Managed Identity
resource "azurerm_app_service" "app" {
  name                = var.app_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.plan.id

  site_config { 
    linux_fx_version = "PYTHON|3.13" 
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "KEY_VAULT_URI"            = azurerm_key_vault.kv.vault_uri
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }

  tags = {
    Owner = var.owner_tag
  }
}

# Grant App Service access to Key Vault secrets
resource "azurerm_key_vault_access_policy" "app_kv_policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_app_service.app.identity.principal_id

  secret_permissions = ["get", "list"]
}

# Custom Policy: Require Owner Tag
resource "azurerm_policy_definition" "require_owner_tag" {
  name         = "Require-Owner-Tag"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Require Owner Tag on all resources"
  description  = "Denies creation of any resource without the 'Owner' tag."
  policy_rule  = file("${path.module}/azure-policies/require_tags.json")
}

resource "azurerm_policy_assignment" "rg_owner_tag" {
  name                 = "require-owner-tag-on-rg"
  scope                = azurerm_resource_group.rg.id
  policy_definition_id = azurerm_policy_definition.require_owner_tag.id

  parameters = {
    tagName = { value = var.owner_tag }
  }
}
