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
  name                = "vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}


####### SUBNET
resource "azurerm_subnet" "subnet" {
  name                 = "subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault"]
  address_prefixes     = ["10.0.1.0/24"]  
}


####### NSG
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.app_name}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow_Azure_Platform"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}


####### KEY VAULT
data "azurerm_key_vault" "kv_base" {
  name                = "kv-base"
  resource_group_name = var.infra_base_resource_group_name
}


####### App Service Plan
resource "azurerm_service_plan" "app_plan" {
  name                = "${var.app_name}-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = var.os_type
  sku_name            = var.sku_name
  # zone_balancing_enabled = true
  # worker_count = 2

  tags = {
    Owner = var.owner_tag
  }
}

data "azurerm_user_assigned_identity" "app_msi" {
  name                = "${var.app_name}-msi" 
  resource_group_name = var.infra_base_resource_group_name
}

####### App Service
resource "azurerm_linux_web_app" "app" {
  name                = var.app_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.app_plan.id
  https_only = true

  logs {
    application_logs {
      file_system_level = "Verbose"
    }
    detailed_error_messages = true
    failed_request_tracing = true
    http_logs {
      file_system {
        retention_in_mb   = 35            # Tamaño máx de logs en disco (MB) antes de rotar
        retention_in_days = 1             # Días de retención de logs de HTTP en filesystem
      }
    }
  }

  site_config {
    health_check_path  = "/health" 
    health_check_eviction_time_in_min = 5                                                        
    http2_enabled = true 
    always_on = true     
    ftps_state = "Disabled"  
    app_command_line  = "gunicorn --bind=0.0.0.0:8000 main:app"

    application_stack {
      python_version = "3.13"
    }   
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.app_msi.id]
  }

  app_settings = {
    KEY_VAULT_URI                     = data.azurerm_key_vault.kv_base.vault_uri
    SCM_DO_BUILD_DURING_DEPLOYMENT    = true
    FLASK_ENV                         = "production"  
    AZURE_CLIENT_ID                   = data.azurerm_user_assigned_identity.app_msi.client_id
  }

  depends_on = [azurerm_service_plan.app_plan]

  tags = {
    Owner = var.owner_tag
  }
}

####### Azure Policy
# Custom policy: Require owner tag
resource "azurerm_policy_definition" "require_owner_tag" {
  name         = "Require-Owner-Tag"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Requerir etiqueta Owner en recursos"
  description  = "Niega creación de recursos que no tengan la etiqueta especificada en 'tagName'."
  policy_rule  = file("${path.module}/../azure-policies/require_tags.json")
  parameters = <<PARAMS
{
  "tagName": {
    "type": "String",
    "defaultValue": "Owner",
    "metadata": {
      "displayName": "Tag Name",
      "description": "Nombre de la etiqueta obligatoria en cada recurso"
    }
  }
}
PARAMS
}

resource "azurerm_resource_group_policy_assignment" "assign_require_owner_tag" {
  name                 = "Require Owner Tag"
  resource_group_id    = azurerm_resource_group.rg.id
  policy_definition_id = azurerm_policy_definition.require_owner_tag.id

  parameters = <<PARAMS
{
  "tagName": {
    "value": "Owner"
  }
}
PARAMS
}

# Custom policy: Allowed Locations
resource "azurerm_policy_definition" "allowed_locations" {
  name         = "Allowed-Locations"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Only allowed locations for TFM RG"
  description  = "Solo regiones westeurope y northeurope."
  policy_rule  = file("${path.module}/../azure-policies/allowed_locations.json")
  parameters = <<PARAMETERS
{
  "allowedLocations": {
    "type": "Array",
    "metadata": {
      "displayName": "Allowed Locations",
      "description": "Lista de regiones autorizadas"
    }
  }
}
PARAMETERS
}

resource "azurerm_resource_group_policy_assignment" "assign_rg_allowed_locations" {
  name                 = "Allowed Locations"
  resource_group_id    = azurerm_resource_group.rg.id
  policy_definition_id = azurerm_policy_definition.allowed_locations.id

  parameters = <<PARAMS
{
  "allowedLocations": {
    "value": [ "westeurope", "northeurope" ]
  }
}
PARAMS
}