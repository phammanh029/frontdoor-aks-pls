resource "azurerm_cdn_frontdoor_profile" "poc" {
  name                = "${var.name_prefix}-afd-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Premium_AzureFrontDoor"
  tags                = local.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "poc" {
  name                     = "${var.name_prefix}-${var.environment}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.poc.id
  enabled                  = true
}

resource "azurerm_cdn_frontdoor_origin_group" "poc" {
  name                     = "gateway"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.poc.id

  session_affinity_enabled = false

  load_balancing {
    sample_size                        = 4
    successful_samples_required        = 3
    additional_latency_in_milliseconds = 50
  }

  health_probe {
    path                = "/"
    request_type        = "HEAD"
    protocol            = "Http"
    interval_in_seconds = 60
  }
}

resource "azurerm_cdn_frontdoor_origin" "poc" {
  name                          = "gateway"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.poc.id
  enabled                       = true

  # For private link origins, AFD still requires these fields.
  host_name          = "${var.subdomain}.${var.dns_zone_name}"
  origin_host_header = "${var.subdomain}.${var.dns_zone_name}"

  http_port  = 80
  https_port = 443

  # PoC: internal LB usually won't have a cert matching this hostname.
  certificate_name_check_enabled = false

  private_link {
    private_link_target_id = data.azurerm_private_link_service.gateway_pls.id
    location               = var.location
    request_message        = "AFD -> AKS Traefik Gateway PLS"
  }

  depends_on = [data.azurerm_private_link_service.gateway_pls]
}

resource "azurerm_cdn_frontdoor_custom_domain" "poc" {
  name                     = "manhp-az-codeleap-net"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.poc.id
  host_name                = "${var.subdomain}.${var.dns_zone_name}"

  tls {
    certificate_type = "ManagedCertificate"
  }
}

resource "azurerm_dns_txt_record" "poc" {
  name                = "_dnsauth.${var.subdomain}.${var.dns_zone_name}"
  zone_name           = data.azurerm_dns_zone.zone.name
  resource_group_name = var.dns_zone_rg
  ttl                 = 3600

  record {
    value = azurerm_cdn_frontdoor_custom_domain.poc.validation_token
  }
}

resource "azurerm_dns_cname_record" "poc" {
  depends_on = [azurerm_cdn_frontdoor_route.poc]

  name                = "manhp"
  zone_name           = data.azurerm_dns_zone.zone.name
  resource_group_name = var.dns_zone_rg
  ttl                 = 3600
  record              = azurerm_cdn_frontdoor_endpoint.poc.host_name
}

resource "azurerm_cdn_frontdoor_route" "poc" {
  name                          = "gateway"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.poc.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.poc.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.poc.id]

  cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.poc.id]

  enabled                = true
  forwarding_protocol    = "HttpOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]
}
