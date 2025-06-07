resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
    name                = "${var.app_name}-log-analytics" 
    location            = var.location
    resource_group_name = var.resource_group_name
    sku                 = var.sku_name
    retention_in_days   = 30
    
    tags = {
        Owner = var.owner_tag
    }
}
