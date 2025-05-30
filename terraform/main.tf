terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.31.0"
    }
  }
}

provider "azurerm" {
  features {}
  storage_use_azuread = true  
}

data "azurerm_client_config" "current" {}
data "azurerm_subscription" "primary" {}

####### RESOURCE GROUP
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    Owner = var.owner_tag
  }
}

####### VIRTUAL NET
resource "azurerm_virtual_network" "vnet" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

####### NSG
resource "azurerm_network_security_group" "endpoint_nsg" {
  name                = "${var.app_name}-endpoint-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow_Azure_Platform"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "AzureCloud"
    destination_address_prefix = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
  }
}

####### SUBNET
resource "azurerm_subnet" "subnet" {
  name                 = "subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault"]
  address_prefixes     = ["10.0.1.0/24"]  
}

resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.endpoint_nsg.id
}

####### KEY VAULT
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
    bypass         = "AzureServices"
  }

  access_policy = []

  tags = {
    Owner = var.owner_tag
  }
}

# Key Vault endpoint
resource "azurerm_private_endpoint" "kv_endpoint" {
  name                = "${var.key_vault_name}-pe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id

  private_service_connection {
    name                           = "kv-privatelink"
    private_connection_resource_id = azurerm_key_vault.kv.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }
}

# Key Vault Dns
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

# Creacion de mysecret
resource "azurerm_key_vault_secret" "my_secret" {
  name         = "MYSECRET"
  value        = var.my_secret_value
  key_vault_id = azurerm_key_vault.kv.id

  content_type    = "text/plain"            
  expiration_date = var.expiry_date  

  depends_on = [
    azurerm_key_vault_access_policy.current
  ]
}


####### STORAGE ACCOUNT
resource "azurerm_storage_account" "app_storage_account" {
  name                     = "saapptfm"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version = "TLS1_2"
  public_network_access_enabled = false
  allow_nested_items_to_be_public = false
  shared_access_key_enabled = false

  network_rules {
    default_action             = "Deny"                     # Bloquea todo por defecto
    bypass                     = ["AzureServices"]         # Permite tráfico interno de Azure (p. ej. diagnósticos)
    virtual_network_subnet_ids = [azurerm_subnet.subnet.id] # Subnet donde correrá tu App/WebApp
  }

  sas_policy {
    expiration_period = "01.12:00:00"
  }

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }
}

# Asigno el rol de data contributor
resource "azurerm_role_assignment" "blob_data_contributor" {
  scope                = azurerm_storage_account.app_storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# SA queue properties
resource "azurerm_storage_account_queue_properties" "sa_properties" {
  storage_account_id = azurerm_storage_account.app_storage_account.id
  logging {
      delete                = true
      read                  = true
      write                 = true
      version               = "1.0"
      retention_policy_days = 10
    }
}

# SA endpoind
resource "azurerm_private_endpoint" "sa_endpoint" {
  name                = "sa-app-pe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id

  private_service_connection {
    name                           = "sa-app-privatelink"
    private_connection_resource_id = azurerm_storage_account.app_storage_account.id
    is_manual_connection           = false
    subresource_names              = ["blob", "file"]
  }
}

# CMK app
resource "azurerm_storage_account_customer_managed_key" "ok_cmk" {
  storage_account_id = azurerm_storage_account.app_storage_account.id
  key_vault_id       = azurerm_key_vault.kv.id
  key_name           = azurerm_key_vault_key.kv_key.name
}

resource "azurerm_key_vault_access_policy" "app_kv_policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.app.identity[0].principal_id
  secret_permissions = ["Get", "List"]
}

resource "azurerm_key_vault_key" "kv_key" {
  name         = "tfex-key"
  key_vault_id = azurerm_key_vault.kv.id
  key_type     = "RSA-HSM"
  key_size     = 2048
  key_opts     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
  expiration_date = var.expiry_date

  depends_on = [
    azurerm_key_vault_access_policy.app_kv_policy
  ]
}

####### App Service Plan
resource "azurerm_service_plan" "app_plan" {
  name                = "${var.app_name}-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "P1v2"
  zone_balancing_enabled = true
  worker_count = 2

  tags = {
    Owner = var.owner_tag
  }
}

####### App Service
resource "azurerm_storage_share" "sa_share" {
  name               = "appshare"
  storage_account_id = azurerm_storage_account.app_storage_account.id
  quota              = 5
}

resource "azurerm_linux_web_app" "app" {
  name                = var.app_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.app_plan.id
  public_network_access_enabled = false
  https_only = true
  client_certificate_enabled           = true
  client_certificate_mode              = "Required"

  logs {
    detailed_error_messages = true
    failed_request_tracing = true
    http_logs {
      file_system {
        retention_in_mb   = 35            # Tamaño máx de logs en disco (MB) antes de rotar
        retention_in_days = 7             # Días de retención de logs de HTTP en filesystem
      }
    }
  }

  storage_account {
    name = "test_name"
    account_name = azurerm_storage_account.app_storage_account.name
    access_key   = azurerm_storage_account.app_storage_account.primary_access_key
    share_name   = azurerm_storage_share.sa_share.name
    mount_path   = "/data"
    type = "AzureFiles"
  }

  site_config {
    health_check_path  = "/health" 
    health_check_eviction_time_in_min = 5                                                        
    http2_enabled      = true 
    always_on = true     
    ftps_state = "Disabled"       
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

####### Access Policy 
resource "azurerm_key_vault_access_policy" "current" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id
  secret_permissions = ["Get","List","Set","Delete"]
}

resource "azurerm_role_assignment" "policy_contributor" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Policy Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Custom Policy: Require Owner Tag
resource "azurerm_policy_definition" "require_owner_tag" {
  name         = "Require-Owner-Tag"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Require Owner Tag on all resources"
  description  = "Denies creation of any resource without the 'Owner' tag."
  policy_rule  = file("${path.module}/../azure-policies/require_tags.json")
  depends_on = [azurerm_role_assignment.policy_contributor]
}

resource "azurerm_resource_group_policy_assignment" "rg_owner_tag" {
  name                 = "require-owner-tag-on-rg"
  resource_group_id    = azurerm_resource_group.rg.id
  policy_definition_id = azurerm_policy_definition.require_owner_tag.id

  parameters = <<PARAMS
{
  "tagName": {
    "value": "${var.owner_tag}"
  }
}
PARAMS
}
