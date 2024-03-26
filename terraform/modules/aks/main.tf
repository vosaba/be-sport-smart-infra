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
    name                        = "default"
    vm_size                     = var.vm_size
    node_count                  = var.node_count
    vnet_subnet_id              = var.vnet_subnet_id
    # Needs for changing VM configuration, temporary place for pod migranitions
    temporary_name_for_rotation = "temp1995name"
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
    service_cidr      = "10.0.2.0/24"
    dns_service_ip    = "10.0.2.10"
  }

  dynamic "key_vault_secrets_provider" {
    for_each = var.key_vault_secrets_provider ? [1] : []
    content {
      secret_rotation_enabled = var.key_vault_secrets_provider
    }
  }

  dynamic "ingress_application_gateway" {
  for_each = var.appgw_id != "" ? [1] : []
  content {
    gateway_name = "ingress-app-gw"
    gateway_id   = var.appgw_id
  }
}

  tags = {
    environment = var.environment
  }
}
