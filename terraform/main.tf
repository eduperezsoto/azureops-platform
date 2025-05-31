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
  name                = "${var.key_vault_name}-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id

  private_service_connection {
    name                           = "kv-app-privatelink"
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

# Asociacion dns y vnet
resource "azurerm_private_dns_zone_virtual_network_link" "kv_dns_link" {
  name                  = "kv-dns-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.kv_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}  

# Registro endpoint en dns
resource "azurerm_private_dns_a_record" "kv_record" {
  name                = replace(var.key_vault_name, "-", "")
  zone_name           = azurerm_private_dns_zone.kv_dns.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [
    azurerm_private_endpoint.kv_endpoint.private_service_connection[0].private_ip_address
  ]
}

resource "azurerm_key_vault_access_policy" "current" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id
  secret_permissions = ["Get","List","Set","Delete"]
  key_permissions    = ["Get","Create","Delete","List"]
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
  name                     = "saapp"
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
    bypass                     = ["AzureServices"]          # Permite tráfico interno de Azure (p. ej. diagnósticos)
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
  name                = "${azurerm_storage_account.app_storage_account.name}-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id

  private_service_connection {
    name                           = "sa-app-privatelink"
    private_connection_resource_id = azurerm_storage_account.app_storage_account.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
}

# Private DNS Zone para file
resource "azurerm_private_dns_zone" "sa_dns" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

# Asociacion dns y vnet
resource "azurerm_private_dns_zone_virtual_network_link" "sa_dns_link" {
  name                  = "sa-dns-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.sa_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}  

# Registro endpoint en dns
resource "azurerm_private_dns_a_record" "sa_record" {
  name                = replace(azurerm_storage_account.app_storage_account.name, "-", "")
  zone_name           = azurerm_private_dns_zone.sa_dns.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [
    azurerm_private_endpoint.sa_endpoint.private_service_connection[0].private_ip_address
  ]
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

####### App Service
resource "azurerm_linux_web_app" "app" {
  name                = var.app_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.app_plan.id
  https_only = true
  client_certificate_enabled           = true
  client_certificate_mode              = "Required"
  public_network_access_enabled = false

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


###### CMK blob storage
# Asigno rol para que la app tenga permisos en el blob
resource "azurerm_role_assignment" "blob_data_contributor" {
  scope                = azurerm_storage_account.app_storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_web_app.app.identity[0].principal_id

  depends_on = [
    azurerm_linux_web_app.app
  ]
}

# Permitir a la app listar y obtener secretos. Tambien se permite que pueda envolver y desenvolver la clave para cifrar datos
resource "azurerm_key_vault_access_policy" "app_kv_policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.app.identity[0].principal_id
  
  secret_permissions = ["Get", "List"]
  key_permissions = ["Get", "UnwrapKey", "WrapKey"]
}


# Cifrar sa con una clave que vive en el kv
resource "azurerm_key_vault_key" "kv_key" {
  name         = "kv-key"
  key_vault_id = azurerm_key_vault.kv.id
  key_type     = "RSA-HSM"
  key_size     = 2048
  key_opts     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
  expiration_date = var.expiry_date

  depends_on = [
    azurerm_key_vault_access_policy.app_kv_policy
  ]
}

# Asocia la key a la storage account para que pueda cifrar datos
resource "azurerm_storage_account_customer_managed_key" "ok_cmk" {
  storage_account_id = azurerm_storage_account.app_storage_account.id
  key_vault_id       = azurerm_key_vault.kv.id
  key_name           = azurerm_key_vault_key.kv_key.name

  depends_on = [
    azurerm_key_vault_key.kv_key
  ]
}


######## APPGW

output "who_am_i" {
  value = {
    client_id   = data.azurerm_client_config.current.client_id
    object_id   = data.azurerm_client_config.current.object_id
    subscription = data.azurerm_client_config.current.subscription_id
    tenant_id   = data.azurerm_client_config.current.tenant_id
  }
}


data "azurerm_key_vault" "kv_base" {
  name                = "kv-base"       # Ajusta al nombre exacto de tu Key Vault
  resource_group_name = var.infra_base_resource_group_name
}

resource "azurerm_role_assignment" "terraform_read_kv" {
  scope                = data.azurerm_key_vault.kv_base.id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# 2. Luego, obtenemos el secret (que contiene el PFX) dentro de ese Key Vault
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
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
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


resource "azurerm_user_assigned_identity" "appgw_msi" {
  name                = "${var.app_name}-appgw-msi"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
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
    identity_ids = [azurerm_user_assigned_identity.appgw_msi.id]
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
    min_protocol_version = "TLSv1_2"
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

resource "azurerm_role_assignment" "appgw_cert_officer" {
  scope                = data.azurerm_key_vault.kv_base.id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = azurerm_application_gateway.appgw.identity[0].principal_id
}


####### Permissions

# resource "azurerm_role_assignment" "policy_contributor" {
#   scope                = data.azurerm_subscription.primary.id
#   role_definition_name = "b24988ac-6180-42a0-ab88-20f7382dd24c" # Policy contributor role
#   principal_id         = data.azurerm_client_config.current.object_id
# }

# Custom Policy: Require Owner Tag
resource "azurerm_policy_definition" "require_owner_tag" {
  name         = "Require-Owner-Tag"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Require Owner Tag on all resources"
  description  = "Denies creation of any resource without the 'Owner' tag."
  policy_rule  = file("${path.module}/../azure-policies/require_tags.json")
  # depends_on = [azurerm_role_assignment.policy_contributor]
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
