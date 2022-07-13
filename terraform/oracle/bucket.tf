resource "oci_objectstorage_bucket" "secretsquirrel" {
  # bucket can't emit object events
  # Storage hasn't versioning enabled
  # Storage isn't encrypted with Customer Managed Key
  # Object Storage is Public"
  compartment_id        = oci_identity_compartment.tf-compartment.id
  name                  = "myreallysecretstore"
  namespace             = data.oci_objectstorage_namespace.example.namespace
  object_events_enabled = false
  access_type           = "ObjectRead"
  metadata              = { "data" = "Blockofdata" }
  storage_tier          = "Standard"
  freeform_tags = {
    git_commit           = "N/A"
    git_file             = "terraform/oracle/bucket.tf"
    git_org              = "zscaler-bd-sa"
    git_repo             = "zs-terraform-iac-scanning"
  }
}



