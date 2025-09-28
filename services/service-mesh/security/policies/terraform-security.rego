# policies/terraform-security.rego
package service_mesh.terraform

# Require encryption for S3 buckets
deny[msg] {
    input.resource_type == "aws_s3_bucket"
    input.resource_name == "service-mesh"
    not input.config.encryption
    msg := "Service Mesh S3 bucket must have encryption enabled"
}

# Require encryption for RDS
deny[msg] {
    input.resource_type == "aws_rds_cluster"
    input.resource_name == "service-mesh"
    not input.config.storage_encrypted
    msg := "Service Mesh RDS cluster must have encryption enabled"
}
