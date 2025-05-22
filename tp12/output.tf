output "container_ipv4_address" {
  value = azurerm_container_group.container.ip_address
}

output "container_dns_name_label" {
  value = azurerm_container_group.container.fqdn
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}