resource "alicloud_oss_bucket" "bad_bucket" {
  # Public and writeable bucket
  # Versioning isn't enabled
  # Not Encrypted with a Customer Master Key and no Server side encryption
  # Doesn't have access logging enabled"
  bucket = "wildwestfreeforall"
  acl    = "public-read-write"
  tags = {
    git_commit           = "N/A"
    git_file             = "terraform/alicloud/bucket.tf"
    git_org              = "zscaler-bd-sa"
    git_repo             = "zs-terraform-iac-scanning"
  }
}
