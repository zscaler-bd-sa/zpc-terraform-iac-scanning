resource azurerm_kubernetes_cluster "k8s_cluster" {
  dns_prefix          = "zs-terraform-iac-scanning-${var.environment}"
  location            = var.location
  name                = "zs-terraform-iac-scanning-aks-${var.environment}"
  resource_group_name = azurerm_resource_group.example.name
  identity {
    type = "SystemAssigned"
  }
  default_node_pool {
    name       = "default"
    vm_size    = "Standard_D2_v2"
    node_count = 2
  }
  addon_profile {
    oms_agent {
      enabled = false
    }
    kube_dashboard {
      enabled = true
    }
  }
  role_based_access_control {
    enabled = false
  }
  tags = {
    git_commit           = "N/A"
    git_file             = "terraform/azure/aks.tf"
    git_org              = "zscaler-bd-sa"
    git_repo             = "zs-terraform-iac-scanning"
  }
}