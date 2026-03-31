output "artifacts_bucket_arn" {
  description = "ARN of the artifacts S3 bucket"
  value       = aws_s3_bucket.artifacts.arn
}

output "artifacts_bucket_name" {
  description = "Name of the artifacts S3 bucket"
  value       = aws_s3_bucket.artifacts.id
}

output "backups_bucket_arn" {
  description = "ARN of the backups S3 bucket"
  value       = aws_s3_bucket.backups.arn
}

output "backups_bucket_name" {
  description = "Name of the backups S3 bucket"
  value       = aws_s3_bucket.backups.id
}

output "logs_bucket_arn" {
  description = "ARN of the logs S3 bucket"
  value       = aws_s3_bucket.logs.arn
}

output "logs_bucket_name" {
  description = "Name of the logs S3 bucket"
  value       = aws_s3_bucket.logs.id
}

output "ml_models_bucket_arn" {
  description = "ARN of the ML models S3 bucket"
  value       = aws_s3_bucket.ml_models.arn
}

output "ml_models_bucket_name" {
  description = "Name of the ML models S3 bucket"
  value       = aws_s3_bucket.ml_models.id
}

output "all_bucket_arns" {
  description = "List of all S3 bucket ARNs"
  value = [
    aws_s3_bucket.artifacts.arn,
    aws_s3_bucket.backups.arn,
    aws_s3_bucket.logs.arn,
    aws_s3_bucket.ml_models.arn
  ]
}
