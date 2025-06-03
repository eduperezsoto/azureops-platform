output "instrumentation_key" {
    description = "Instrumentation key"
    value = azurerm_application_insights.application_insights.instrumentation_key 
}

output "connection_string" {
    description = "Connection String"
    value = azurerm_application_insights.application_insights.connection_string 
}