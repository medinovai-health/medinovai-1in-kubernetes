package terraform.security

deny[msg] {
  some r
  input.resource_changes[r].type == "aws_s3_bucket"
  not input.resource_changes[r].change.after.server_side_encryption_configuration
  msg := sprintf("S3 bucket %v missing SSE configuration", [input.resource_changes[r].name])
}

deny[msg] {
  some r
  input.resource_changes[r].type == "aws_db_instance"
  not input.resource_changes[r].change.after.storage_encrypted
  msg := sprintf("RDS instance %v must enable storage_encrypted", [input.resource_changes[r].name])
}

deny[msg] {
  some r
  input.resource_changes[r].type == "aws_iam_policy"
  actions := input.resource_changes[r].change.after.statement[_].action
  actions == ["*"]
  msg := sprintf("IAM policy %v must not allow Action:*", [input.resource_changes[r].name])
}
