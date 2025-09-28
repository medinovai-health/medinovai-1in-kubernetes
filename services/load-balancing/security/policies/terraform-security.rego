# policies/terraform-security.rego
package load_balancing.terraform

# Require encryption for S3 buckets
deny[msg] {
    input.resource_type == "aws_s3_bucket"
    input.resource_name == "load-balancing"
    not input.config.encryption
    msg := "Load Balancing S3 bucket must have encryption enabled"
}

# Require encryption for RDS
deny[msg] {
    input.resource_type == "aws_rds_cluster"
    input.resource_name == "load-balancing"
    not input.config.storage_encrypted
    msg := "Load Balancing RDS cluster must have encryption enabled"
}
