####### App Service
data "azurerm_user_assigned_identity" "app_msi" {
  name                = "${var.app_name}-msi" 
  resource_group_name = var.infra_base_resource_group_name
}

resource "azurerm_linux_web_app" "app" {
  name                = var.app_name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = var.service_plan_id
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
    minimum_tls_version = 1.3                                                 
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
    KEY_VAULT_URI                         = var.key_vault_uri
    SCM_DO_BUILD_DURING_DEPLOYMENT        = true
    FLASK_ENV                             = "development"  
    AZURE_CLIENT_ID                       = data.azurerm_user_assigned_identity.app_msi.client_id
    APPLICATIONINSIGHTS_CONNECTION_STRING = var.connection_string
    APPINSIGHTS_INSTRUMENTATIONKEY        = var.instrumentation_key
  }

  tags = {
    Owner = var.owner_tag
  }
}

resource "azurerm_monitor_diagnostic_setting" "diag_appservice" {
  name               = "${var.app_name}-diag-settings" 
  target_resource_id = azurerm_linux_web_app.app.id
  log_analytics_workspace_id = var.workspace_id

  enabled_log {
    category = "AppServiceHTTPLogs"    # Peticiones HTTP entrantes
  }

  enabled_log {
    category = "AppServiceAppLogs"     # app.logger.info(), errores de Flask, etc.
  }

  enabled_log {
    category = "AppServiceConsoleLogs" # Mensajes que Gunicorn imprime, prints inesperados, etc.
  }

  enabled_log {
    category = "AppServicePlatformLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}