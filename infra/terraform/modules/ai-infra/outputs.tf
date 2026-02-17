# -----------------------------------------------------------------------------
# AI Infrastructure Module Outputs - MedinovAI
# -----------------------------------------------------------------------------

output "model_artifacts_bucket_arn" {
  description = "ARN of the S3 bucket for model artifacts"
  value       = aws_s3_bucket.model_artifacts.arn
}

output "model_artifacts_bucket_name" {
  description = "Name of the S3 bucket for model artifacts"
  value       = aws_s3_bucket.model_artifacts.id
}

output "ecr_repository_url" {
  description = "URL of the ECR repository for ML model images"
  value       = aws_ecr_repository.ml_models.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository for ML model images"
  value       = aws_ecr_repository.ml_models.arn
}

output "sagemaker_endpoint_name" {
  description = "Name of the SageMaker endpoint (when enabled)"
  value       = var.enable_sagemaker ? aws_sagemaker_endpoint.main[0].name : null
}

output "sagemaker_role_arn" {
  description = "ARN of the SageMaker execution IAM role (when enabled)"
  value       = var.enable_sagemaker ? aws_iam_role.sagemaker[0].arn : null
}

output "inference_log_group_name" {
  description = "CloudWatch log group name for inference logs"
  value       = aws_cloudwatch_log_group.inference.name
}
