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
        retention_in_mb   = 35  
        retention_in_days = 1
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
      python_version = var.app_python_version
    }   
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.app_msi.id]
  }

  app_settings = {
    KEY_VAULT_URI                         = var.key_vault_uri
    SCM_DO_BUILD_DURING_DEPLOYMENT        = true
    FLASK_ENV                             = var.app_env  
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
    category = "AppServiceHTTPLogs"
  }

  enabled_log {
    category = "AppServiceAppLogs"   
  }

  enabled_log {
    category = "AppServiceConsoleLogs" 
  }

  enabled_log {
    category = "AppServicePlatformLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}