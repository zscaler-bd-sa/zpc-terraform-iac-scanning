resource "google_sql_database_instance" "master_instance" {
  name             = "zs-terraform-iac-scanning-${var.environment}-master"
  database_version = "POSTGRES_11"
  region           = var.region

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled = true
      authorized_networks {
        name  = "WWW"
        value = "0.0.0.0/0"
      }
    }
    backup_configuration {
      enabled = false
    }
  }
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id = "zs-terraform-iac-scanning_${var.environment}_dataset"
  access {
    special_group = "allAuthenticatedUsers"
    role          = "READER"
  }
  labels = {
    git_commit           = "N/A"
    git_file             = "terraform/gcp/big_data.tf"
    git_org              = "zscaler-bd-sa"
    git_repo             = "zs-terraform-iac-scanning"
  }
}