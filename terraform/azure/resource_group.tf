resource "azurerm_resource_group" "example" {
  name     = "zs-terraform-iac-scanning-${var.environment}"
  location = var.location
  tags = {
    git_commit           = "N/A"
    git_file             = "terraform/azure/resource_group.tf"
    git_org              = "zscaler-bd-sa"
    git_repo             = "zs-terraform-iac-scanning"
  }
}