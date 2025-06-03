output "service_plan_id" {
  description = "Id of the service plan"
  value        = azurerm_service_plan.app_plan.id
}
