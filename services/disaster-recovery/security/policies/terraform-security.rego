# policies/terraform-security.rego
package disaster_recovery.terraform

# Require encryption for S3 buckets
deny[msg] {
    input.resource_type == "aws_s3_bucket"
    input.resource_name == "disaster-recovery"
    not input.config.encryption
    msg := "Disaster Recovery S3 bucket must have encryption enabled"
}

# Require encryption for RDS
deny[msg] {
    input.resource_type == "aws_rds_cluster"
    input.resource_name == "disaster-recovery"
    not input.config.storage_encrypted
    msg := "Disaster Recovery RDS cluster must have encryption enabled"
}
