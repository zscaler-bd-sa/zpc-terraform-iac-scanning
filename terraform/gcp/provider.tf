provider "google" {
  credentials = file(var.credentials_path)
  project = var.project
  region  = var.region
}


terraform {
  backend "gcs" {
    credentials = var.credentials_path
    prefix      = "zs-terraform-iac-scanning/${var.environment}"
  }
}