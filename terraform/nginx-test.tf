# --- NGINX test workload (deployment + service) ---
resource "kubernetes_namespace_v1" "test" {
  metadata {
    name = "test"
  }
  depends_on = [azurerm_kubernetes_cluster.aks]
}

resource "kubernetes_deployment_v1" "nginx" {
  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace_v1.test.metadata[0].name
    labels = {
      app = "nginx"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:1.27-alpine"

          port {
            name           = "http"
            container_port = 80
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "nginx" {
  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace_v1.test.metadata[0].name
    labels = {
      app = "nginx"
    }
  }

  spec {
    selector = {
      app = "nginx"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

# --- HTTPRoute -> Traefik Gateway ---
# This needs the Gateway API CRDs installed (Traefik chart normally does that when gateway is enabled).
# If CRDs are not present yet at plan time, apply Traefik first, then apply again.

resource "kubernetes_manifest" "nginx_route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "nginx-route"
      namespace = kubernetes_namespace_v1.test.metadata[0].name
    }
    spec = {
      parentRefs = [
        {
          # Traefik's gateway name/namespace.
          # If your Traefik values set a different gateway name/namespace, update here.
          name      = "traefik-gateway"
          namespace = "traefik"
          sectionName = "web"
        }
      ]
      hostnames = [
        "${var.subdomain}.${var.dns_zone_name}"
      ]
      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/"
              }
            }
          ]
          backendRefs = [
            {
              name = kubernetes_service_v1.nginx.metadata[0].name
              port = 80
            }
          ]
        }
      ]
    }
  }

  depends_on = [
    helm_release.traefik,
    kubernetes_service_v1.nginx
  ]
}
