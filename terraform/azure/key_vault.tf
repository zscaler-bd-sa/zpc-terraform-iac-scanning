resource "azurerm_key_vault" "example" {
  name                = "zs-terraform-iac-scanning-key-${var.environment}${random_integer.rnd_int.result}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    key_permissions = [
      "create",
      "get",
    ]
    secret_permissions = [
      "set",
    ]
  }
  tags = merge({
    environment               = var.environment
    zs-terraform-iac-scanning = true
    }, {
    git_commit           = "N/A"
    git_file             = "terraform/azure/key_vault.tf"
    git_org              = "zscaler-bd-sa"
    git_repo             = "zs-terraform-iac-scanning"
  })
}

resource "azurerm_key_vault_key" "generated" {
  name         = "zs-terraform-iac-scanning-generated-certificate-${var.environment}"
  key_vault_id = azurerm_key_vault.example.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
  tags = {
    git_commit           = "N/A"
    git_file             = "terraform/azure/key_vault.tf"
    git_org              = "zscaler-bd-sa"
    git_repo             = "zs-terraform-iac-scanning"
  }
}

resource "azurerm_key_vault_secret" "secret" {
  key_vault_id = azurerm_key_vault.example.id
  name         = "zs-terraform-iac-scanning-secret-${var.environment}"
  value        = random_string.password.result
  tags = {
    git_commit           = "N/A"
    git_file             = "terraform/azure/key_vault.tf"
    git_org              = "zscaler-bd-sa"
    git_repo             = "zs-terraform-iac-scanning"
  }
}