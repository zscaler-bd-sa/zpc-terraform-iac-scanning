resource "oci_identity_compartment" "tf-compartment" {
  compartment_id = var.tenancy_id
  description    = "Compartment for Terraform resources."
  name           = "third-compartment"
  enable_delete  = true
  freeform_tags = {
    git_commit           = "N/A"
    git_file             = "terraform/oracle/compartment.tf"
    git_org              = "zscaler-bd-sa"
    git_repo             = "zs-terraform-iac-scanning"
  }
}