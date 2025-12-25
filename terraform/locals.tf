locals {
  rg_name  = "${var.name_prefix}-${var.environment}"
  vnet_name = "${var.name_prefix}-vnet-${var.environment}"

  tags = {
    owner = "manhp"
    env   = var.environment
    app   = "afd-aks-pls-poc"
  }

  traefik_config = {
    version                  = "38.0.1"
    minReplicas              = var.is_production_grade_environment ? 3 : 1
    maxReplicas              = 10
    cpu_target_percentage    = 70
    memory_target_percentage = 70
  }

  traefik_service_annotations_base = {
    "service.beta.kubernetes.io/azure-load-balancer-internal"                     = "true"
    "service.beta.kubernetes.io/azure-pls-create"                                 = "true"
    "service.beta.kubernetes.io/azure-pls-name"                                   = "gateway-pls-${var.environment}"
    "service.beta.kubernetes.io/azure-pls-ip-configuration-subnet"                = "private-link"
    "service.beta.kubernetes.io/azure-pls-ip-configuration-ip-address-count"      = 1
    "service.beta.kubernetes.io/azure-pls-proxy-protocol"                         = "false"
    "service.beta.kubernetes.io/azure-pls-visibility"                             = "*"
  }

  # If you set traefik_ilb_static_ip, add the annotation for a fixed ILB IP.
  traefik_service_annotations = (
    var.traefik_ilb_static_ip != ""
    ? merge(local.traefik_service_annotations_base, {
        "service.beta.kubernetes.io/azure-load-balancer-ipv4" = var.traefik_ilb_static_ip
      })
    : local.traefik_service_annotations_base
  )

  helm_values = {
    # resources = {
    #   limits = {
    #     cpu    = "500m"
    #     memory = "1Gi"
    #   }
    #   requests = {
    #     cpu    = "250m"
    #     memory = "512Mi"
    #   }
    # }

    ports = {
      websecure = {
        expose = { default = false }
        tls    = { enabled = false }
      }
    }

    providers = {
      kubernetesIngress = { enabled = false }
      kubernetesGateway = { enabled = true }
    }

    gateway = {
      enabled = true
      listeners = {
        web = {
          namespacePolicy = { from = "All" }
        }
      }
    }

    service = {
      type        = "LoadBalancer"
      annotations = local.traefik_service_annotations
    }

    autoscaling = {
      enabled     = true
      minReplicas = local.traefik_config.minReplicas
      maxReplicas = local.traefik_config.maxReplicas
      metrics = [
        {
          type = "Resource"
          resource = {
            name = "cpu"
            target = {
              type               = "Utilization"
              averageUtilization = local.traefik_config.cpu_target_percentage
            }
          }
        },
        {
          type = "Resource"
          resource = {
            name = "memory"
            target = {
              type               = "Utilization"
              averageUtilization = local.traefik_config.memory_target_percentage
            }
          }
        }
      ]
    }
  }
}
