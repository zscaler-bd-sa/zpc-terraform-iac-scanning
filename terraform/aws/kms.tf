resource "aws_kms_key" "logs_key" {
  # key does not have rotation enabled
  description = "${local.resource_prefix.value}-logs bucket key"

  deletion_window_in_days = 7
  tags = merge({
    Name        = "${local.resource_prefix.value}-og"
    Environment = local.resource_prefix.value
    },{
    git_commit           = "N/A"
    git_file             = "terraform/aws/kms.tf"
    git_org              = "zscaler-bd-sa"
    git_repo             = "zs-terraform-iac-scanning"
    })
}

resource "aws_kms_alias" "logs_key_alias" {
  name          = "alias/${local.resource_prefix.value}-logs-bucket-key"
  target_key_id = "${aws_kms_key.logs_key.key_id}"
}
