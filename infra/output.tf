output "docker_registry_server_url" {
  value       = replace(azurerm_container_registry.acr.login_server, "https://", "")
  description = "ACR login server URL without 'https://'. Add this to GitHub secrets as DOCKER_REGISTRY_SERVER_URL."
}

output "docker_registry_server_username" {
  value       = azurerm_container_registry.acr.admin_username
  description = "ACR admin username. Add this to GitHub secrets as DOCKER_REGISTRY_SERVER_USERNAME."
}

output "docker_registry_server_password" {
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
  description = "ACR admin password. Add this to GitHub secrets as DOCKER_REGISTRY_SERVER_PASSWORD."
}

# Output Function App publish profile
output "GET_PUBLISHING_PROFILE_SCRIPT" {
  value       = "az webapp deployment list-publishing-profiles --name ${azurerm_linux_web_app.app.name} --resource-group ${azurerm_resource_group.rg.name} --xml"
  description = "Run this command in your shell to retrieve the Azure Web App's publishing profile. Add the result to GitHub secrets as AZURE_WEBAPP_PUBLISH_PROFILE."
}
