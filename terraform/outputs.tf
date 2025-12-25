output "frontdoor_endpoint_host" {
  value = azurerm_cdn_frontdoor_endpoint.poc.host_name
}

output "custom_domain" {
  value = "${var.subdomain}.${var.dns_zone_name}"
}

output "aks_node_resource_group" {
  value = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "pls_id" {
  value = data.azurerm_private_link_service.gateway_pls.id
}

output "traefik_service_ip" {
  value = try(data.kubernetes_resources.traefik_service.objects[0].status.loadBalancer.ingress[0].ip, null)
}
