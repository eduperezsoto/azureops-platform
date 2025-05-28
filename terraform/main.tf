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

# Vnet
resource "azurerm_virtual_network" "vnet" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Endpoint subnet
resource "azurerm_subnet" "endpoint" {
  name                 = "endpoint"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Key Vault
resource "azurerm_key_vault" "kv" {
  name                        = var.key_vault_name
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = true
  soft_delete_retention_days  = 90
  
  public_network_access_enabled = false 

  network_acls {
    default_action = "Deny"             
    bypass         = ["AzureServices"]  
  }

  access_policy = []

  tags = {
    Owner = var.owner_tag
  }
}

# Secret con content-type y expiry
resource "azurerm_key_vault_secret" "my_secret" {
  name         = "MY_SECRET"
  value        = var.my_secret_value
  key_vault_id = azurerm_key_vault.kv.id

  content_type    = "text/plain"            
  expiration_date = var.my_secret_expiry  
}

# 3. Private Endpoint + DNS privado para Key Vault
resource "azurerm_private_endpoint" "kv_pe" {
  name                = "${var.key_vault_name}-pe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.endpoint.id

  private_service_connection {
    name                           = "kv-privatelink"
    private_connection_resource_id = azurerm_key_vault.kv.id
    is_manual_connection           = false
  }
}

resource "azurerm_private_dns_zone" "kv_dns" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv_dns_link" {
  name                  = "kv-dns-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.kv_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}  

# App Service Plan
resource "azurerm_service_plan" "plan" {
  name                = "${var.app_name}-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B1"
  zone_balancing_enabled = true

  tags = {
    Owner = var.owner_tag
  }
}

# App Service con Auth, Client Cert y HTTP/2
resource "azurerm_linux_web_app" "app" {
  name                = var.app_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {
    health_check_path  = "/health"                                                         
    http2_enabled      = true                                   
  }

  identity {
    type = "SystemAssigned"
  }

  auth_settings {
    enabled = true
  }

  app_settings = {
    "KEY_VAULT_URI"            = azurerm_key_vault.kv.vault_uri
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }

  tags = {
    Owner = var.owner_tag
  }
}

# Access Policy 
resource "azurerm_key_vault_access_policy" "current" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id
  secret_permissions = ["get","list","set","delete"]
}

resource "azurerm_key_vault_access_policy" "app_kv_policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.app.identity[0].principal_id
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

resource "azurerm_resource_group_policy_assignment" "rg_owner_tag" {
  name                 = "require-owner-tag-on-rg"
  resource_group_id    = azurerm_resource_group.rg.id
  policy_definition_id = azurerm_policy_definition.require_owner_tag.id

  parameters = {
    tagName = { 
      value = var.owner_tag 
    }
  }
}
