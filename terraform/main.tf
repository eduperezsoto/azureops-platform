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
  os_type             = "Linux"
  sku_name            = "P0v3"
  zone_balancing_enabled = true
  worker_count = 2

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
  # client_certificate_enabled           = true
  # client_certificate_mode              = "Required"
  # public_network_access_enabled = false

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
    http2_enabled      = true 
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

  # auth_settings {
  #   enabled = true
  # }

  app_settings = {
    "KEY_VAULT_URI"            = data.azurerm_key_vault.kv_base.vault_uri
    SCM_DO_BUILD_DURING_DEPLOYMENT   = true
    # FLASK_APP                  = "main.py"
    FLASK_ENV                  = "production"  
    AZURE_CLIENT_ID               = data.azurerm_user_assigned_identity.app_msi.client_id
  }

  tags = {
    Owner = var.owner_tag
  }
}
/*
# Crear un Private Endpoint para que tu App Service sea accesible solo por IP interna
resource "azurerm_private_endpoint" "app_endpoint" {
  name                = "${var.app_name}-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id

  private_service_connection {
    name                           = "app-privatelink"
    private_connection_resource_id = azurerm_linux_web_app.app.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }
}

# Private DNS Zone para que 'miapp.azurewebsites.net' resuelva a la IP privada
resource "azurerm_private_dns_zone" "app_dns" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "app_dns_link" {
  name                  = "app-dns-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.app_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_a_record" "app_record" {
  name                = var.app_name
  zone_name           = azurerm_private_dns_zone.app_dns.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [
    azurerm_private_endpoint.app_endpoint.private_service_connection[0].private_ip_address
  ]
}

######## APPGW

# obtenemos el secret (que contiene el PFX) dentro de ese Key Vault
data "azurerm_key_vault_certificate" "appgw_ssl_cert" {
  name         = "ssl-appgw-dev"                # El mismo nombre que pusiste al generarlo (ssl-appgw-dev)
  key_vault_id = data.azurerm_key_vault.kv_base.id
}

# Subnet dedicado para el Application Gateway
resource "azurerm_subnet" "appgw_subnet" {
  name                 = "ag-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "appgw_nsg" {
  name                = "${var.app_name}-gw-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Permitir Azure Load Balancer Health Probes
  security_rule {
    name                       = "Allow_AzureLoadBalancer"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
    source_port_range          = "*"
    destination_port_ranges     = ["65200-65535"]
  }

  # Permitir tráfico público desde Internet a puertos 80/443 (o los que uses)
  security_rule {
    name                       = "Allow_Internet_to_AGW"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["443"]   # ajusta si tu AGW escucha en otros puertos
  }

  # (Opcional) Permitir tráfico interno de la VNet
  security_rule {
    name                       = "Allow_VNet_to_AGW"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
  }

  tags = {
    Owner = var.owner_tag
  }
}

resource "azurerm_subnet_network_security_group_association" "appgw_nsg_association" {
  subnet_id                 = azurerm_subnet.appgw_subnet.id
  network_security_group_id = azurerm_network_security_group.appgw_nsg.id
}

# IP Pública para Application Gateway
resource "azurerm_public_ip" "agw_pip" {
  name                = "agw-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# IP Privada dentro del Subnet AG para manejar el tráfico backend
resource "azurerm_public_ip" "agw_frontend_pip" {
  name                = "agw-fe-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# resource "azurerm_user_assigned_identity" "appgw_msi" {
#   name                = "${var.app_name}-appgw-msi"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
# }

# resource "azurerm_role_assignment" "appgw_cert_officer" {
#   scope                = data.azurerm_key_vault.kv_base.id
#   role_definition_name = "Key Vault Certificates Officer"
#   principal_id         = azurerm_user_assigned_identity.appgw_msi.principal_id
# }

data "azurerm_user_assigned_identity" "appgw_msi" {
  name                = "${var.app_name}-appgw-msi" 
  resource_group_name = var.infra_base_resource_group_name
}

# Application Gateway WAF v2
resource "azurerm_application_gateway" "appgw" {
  name                = "appgw"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  
  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.appgw_msi.id]
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  frontend_port {
    name = "frontendPort"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "appgw-front-ipcfg"
    public_ip_address_id = azurerm_public_ip.agw_pip.id
  }

  ssl_certificate {
    name     = "appgw-ssl-cert"
    key_vault_secret_id = data.azurerm_key_vault_certificate.appgw_ssl_cert.secret_id
  }

  ssl_policy {
    policy_type          = "Predefined"
    policy_name          = "AppGwSslPolicy20220101S"  # fuerza TLS 1.2+
    # min_protocol_version = "TLSv1_2"
  }

  backend_address_pool {
    name = "appservice-backendpool"
    # En lugar de agregar IPs estáticas, usaremos un FQDN (privado) que resuelve a la IP del PE
    fqdns = [format("%s.privatelink.azurewebsites.net", azurerm_linux_web_app.app.name)]
  }

  backend_http_settings {
    name                  = "httpsettings"
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 30
    pick_host_name_from_backend_address = true
  }

  http_listener {
    name                           = "listener-https"
    frontend_ip_configuration_name = "appgw-front-ipcfg"
    frontend_port_name             = "frontendPort"
    protocol                       = "Https"
    ssl_certificate_name           = "appgw-ssl-cert"
  }

  request_routing_rule {
    name                       = "rule1"
    rule_type                  = "Basic"
    http_listener_name         = "listener-https"
    backend_address_pool_name  = "appservice-backendpool"
    backend_http_settings_name = "httpsettings"
    priority = 100
  }

  waf_configuration {
    enabled            = true
    firewall_mode      = "Prevention"
    rule_set_type      = "OWASP"
    rule_set_version   = "3.2"
  }

  tags = {
    Owner = var.owner_tag
  }
}
*/

####### Custom Policy
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