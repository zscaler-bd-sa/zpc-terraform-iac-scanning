data "google_compute_zones" "zones" {}

resource "google_compute_instance" "server" {
  machine_type = "n1-standard-1"
  name         = "zs-terraform-iac-scanning-${var.environment}-machine"
  zone         = data.google_compute_zones.zones.names[0]
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
    auto_delete = true
  }
  network_interface {
    subnetwork = google_compute_subnetwork.public-subnetwork.name
    access_config {}
  }
  can_ip_forward = true

  metadata = {
    block-project-ssh-keys = false
    enable-oslogin         = false
    serial-port-enable     = true
  }
  labels = {
    git_commit           = "N/A"
    git_file             = "terraform/gcp/instances.tf"
    git_org              = "zscaler-bd-sa"
    git_repo             = "zs-terraform-iac-scanning"
  }
}

resource "google_compute_disk" "unencrypted_disk" {
  name = "zs-terraform-iac-scanning-${var.environment}-disk"
  labels = {
    git_commit           = "N/A"
    git_file             = "terraform/gcp/instances.tf"
    git_org              = "zscaler-bd-sa"
    git_repo             = "zs-terraform-iac-scanning"
  }
}