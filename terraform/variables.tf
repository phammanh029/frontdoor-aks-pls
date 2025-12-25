variable "environment" {
  type        = string
  description = "e.g. dev, qa"
  default     = "dev"
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "name_prefix" {
  type    = string
  default = "manhp-poc"
}

variable "dns_zone_name" {
  type        = string
  description = "Existing Azure DNS zone name"
  default     = "az.codeleap.net"
}

variable "dns_zone_rg" {
  type        = string
  description = "Resource group of existing Azure DNS zone"
}

variable "subdomain" {
  type        = string
  description = "The subdomain to create in the zone"
  default     = "manhp"
}

variable "aks_kubernetes_version" {
  type    = string
  default = null
}

variable "aks_node_vm_size" {
  type    = string
  default = "Standard_D4s_v5"
}

variable "aks_node_count" {
  type    = number
  default = 2
}

variable "is_production_grade_environment" {
  type    = bool
  default = false
}

# Optional: force a specific ILB IP for Traefik (so you can change it later deterministically)
variable "traefik_ilb_static_ip" {
  type        = string
  description = "Optional private IP in AKS subnet for the internal LB. Leave empty for dynamic."
  default     = ""
}
