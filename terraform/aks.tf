resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.name_prefix}-aks-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.name_prefix}-${var.environment}"

  kubernetes_version = var.aks_kubernetes_version

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
  }

  default_node_pool {
    name                 = "system"
    vm_size              = var.aks_node_vm_size
    node_count           = var.aks_node_count
    vnet_subnet_id       = azurerm_subnet.aks.id
    orchestrator_version = var.aks_kubernetes_version
    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  tags = local.tags
}

# grant network contributor to the AKS managed identity on the RG containing the VNet
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}