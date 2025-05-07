output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "static_website_url" {
  value = azurerm_storage_account.my_storage_account.primary_web_endpoint
}