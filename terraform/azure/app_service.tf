resource azurerm_app_service_plan "example" {
  name                = "zs-terraform-iac-scanning-app-service-plan-${var.environment}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  sku {
    tier = "Dynamic"
    size = "S1"
  }
  tags = {
    git_file             = "terraform/azure/app_service.tf"
    git_org              = "zscaler-bd-sa"
    git_repo             = "zs-terraform-iac-scanning"
  }
}

resource azurerm_app_service "app-service1" {
  app_service_plan_id = azurerm_app_service_plan.example.id
  location            = var.location
  name                = "zs-terraform-iac-scanning-app-service-${var.environment}${random_integer.rnd_int.result}"
  resource_group_name = azurerm_resource_group.example.name
  https_only          = false
  site_config {
    min_tls_version = "1.1"
  }
  tags = {
    git_file             = "terraform/azure/app_service.tf"
    git_org              = "zscaler-bd-sa"
    git_repo             = "zs-terraform-iac-scanning"
  }
}

resource azurerm_app_service "app-service2" {
  app_service_plan_id = azurerm_app_service_plan.example.id
  location            = var.location
  name                = "zs-terraform-iac-scanning-app-service-${var.environment}${random_integer.rnd_int.result}"
  resource_group_name = azurerm_resource_group.example.name
  https_only          = true

  auth_settings {
    enabled = false
  }
  tags = {
    git_commit           = "N/A"
    git_file             = "terraform/azure/app_service.tf"
    git_org              = "zscaler-bd-sa"
    git_repo             = "zs-terraform-iac-scanning"
  }
}

