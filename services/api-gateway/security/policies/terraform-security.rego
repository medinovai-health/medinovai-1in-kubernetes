# policies/terraform-security.rego
package api_gateway.terraform

# Require encryption for S3 buckets
deny[msg] {
    input.resource_type == "aws_s3_bucket"
    input.resource_name == "api-gateway"
    not input.config.encryption
    msg := "Api Gateway S3 bucket must have encryption enabled"
}

# Require encryption for RDS
deny[msg] {
    input.resource_type == "aws_rds_cluster"
    input.resource_name == "api-gateway"
    not input.config.storage_encrypted
    msg := "Api Gateway RDS cluster must have encryption enabled"
}
