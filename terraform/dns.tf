data "azurerm_dns_zone" "zone" {
  name                = var.dns_zone_name
  resource_group_name = var.dns_zone_rg
}

# CNAME: manhp.az.codeleap.net -> <endpoint>.z01.azurefd.net
resource "azurerm_dns_cname_record" "manhp" {
  name                = var.subdomain
  zone_name           = data.azurerm_dns_zone.zone.name
  resource_group_name = data.azurerm_dns_zone.zone.resource_group_name
  ttl                 = 300
  record              = azurerm_cdn_frontdoor_endpoint.poc.host_name
}
