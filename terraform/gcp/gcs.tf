resource "google_storage_bucket" "zs-terraform-iac-scanning_website" {
  name          = "zscaler-${var.environment}"
  location      = var.location
  force_destroy = true
  labels = {
    git_commit           = "N/A"
    git_file             = "terraform/gcp/gcs.tf"
    git_org              = "zscaler-bd-sa"
    git_repo             = "zs-terraform-iac-scanning"
  }
}

resource "google_storage_bucket_iam_binding" "allow_public_read" {
  bucket  = google_storage_bucket.zs-terraform-iac-scanning_website.id
  members = ["allUsers"]
  role    = "roles/storage.objectViewer"
}