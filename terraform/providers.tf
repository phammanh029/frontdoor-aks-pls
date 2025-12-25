provider "azurerm" {
  subscription_id = var.subscription_id

  features {}
}

data "azurerm_client_config" "current" {}


data "azurerm_kubernetes_cluster" "aks" {
  name                = azurerm_kubernetes_cluster.aks.name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "local_file" "kubeconfig" {
  content  = data.azurerm_kubernetes_cluster.aks.kube_config_raw
  filename = "../.kube/config"
}

resource "null_resource" "wait_for_kubeconfig" {
  provisioner "local-exec" {
    command = "sleep 10"

  }

  depends_on = [local_file.kubeconfig]
}

provider "kubernetes" {
  config_path = local_file.kubeconfig.filename
}

# Helm provider does not need kube config here for this PoC
provider "helm" {
  kubernetes = {
    config_path = local_file.kubeconfig.filename
  }
}
