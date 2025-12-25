resource "kubernetes_namespace_v1" "gateway" {
  metadata {
    name = "traefik"
  }
  depends_on = [azurerm_kubernetes_cluster.aks]
}

resource "helm_release" "traefik" {
  name       = "traefik"
  namespace  = kubernetes_namespace_v1.gateway.metadata[0].name
  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  version    = local.traefik_config.version

  values = [yamlencode(local.helm_values)]

  # PoC-friendly
  atomic           = true
  cleanup_on_fail  = false
  # timeout after 15 minutes
  timeout          = 900
  create_namespace = false

  depends_on = [kubernetes_namespace_v1.gateway]
}

# Read the AKS-created Private Link Service (created by the Service annotation)
data "azurerm_private_link_service" "gateway_pls" {
  name                = "gateway-pls-${var.environment}"
  resource_group_name = azurerm_kubernetes_cluster.aks.node_resource_group

  depends_on = [helm_release.traefik]
}

# Optional helper: read Traefik Service to see its ILB IP quickly
data "kubernetes_resources" "traefik_service" {
  api_version    = "v1"
  kind           = "Service"
  namespace      = kubernetes_namespace_v1.gateway.metadata[0].name
  label_selector = "app.kubernetes.io/name=traefik"

  depends_on = [helm_release.traefik]
}
