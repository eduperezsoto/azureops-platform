output "app_default_hostname" {
  value = azurerm_app_service.app.default_site_hostname
}

output "key_vault_uri" {
  value = azurerm_key_vault.kv.vault_uri
}
