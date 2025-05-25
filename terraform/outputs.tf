output "app_url" {
  description = "Full URL of the deployed App Service"
  value       = "https://${azurerm_app_service.app.default_site_hostname}/"
}
