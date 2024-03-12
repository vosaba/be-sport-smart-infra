# resource "random_pet" "azurerm_kubernetes_cluster_dns_prefix" {
#   prefix = "dns"
# }

terraform {
  required_providers {
    azapi = {
      source = "azure/azapi"
      version = "~> 1.12.0"
    }
  }
}

resource "azurerm_kubernetes_cluster" "k8s" {
  name                = "${var.name}-aks"
  location            = var.location
  resource_group_name = var.rg_name
  dns_prefix          = "${var.name}-aks"
  kubernetes_version  = var.k8s_version
  sku_tier            = var.sku_tier

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name           = "default"
    vm_size        = var.vm_size
    node_count     = var.node_count
    vnet_subnet_id = var.vnet_subnet_id
  }

  linux_profile {
    admin_username = var.username
    ssh_key {
      key_data = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
    }
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    network_policy    = "azure"
  }

  tags = {
    environment = var.environment
  }
}

# resource "azurerm_role_assignment" "k8s" {
#   count = var.container_registry_id ? 1 : 0
#   principal_id                     = azurerm_kubernetes_cluster.k8s.kubelet_identity[0].object_id
#   role_definition_name             = "AcrPull"
#   scope                            = var.container_registry_id
#   skip_service_principal_aad_check = true
# }