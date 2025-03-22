output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "public_ip_address" {
  value = azurerm_public_ip.public_ip.ip_address
}

output "acr_login_server" {
  description = "ACR server"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_admin_username" {
  description = "ACR user"
  value       = azurerm_container_registry.acr.admin_username
}

output "acr_admin_password" {
  description = "ACR login passwd"
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true  #
}