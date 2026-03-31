# -----------------------------------------------------------------------------
# MedinovAI Environment Outputs
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.compute.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.compute.cluster_name
}

output "db_endpoint" {
  description = "RDS endpoint"
  value       = module.database.db_endpoint
}

output "redis_endpoint" {
  description = "Redis primary endpoint"
  value       = module.database.redis_endpoint
}

output "certificate_arn" {
  description = "ACM certificate ARN (when domain_name is set)"
  value       = var.domain_name != "" ? module.dns[0].certificate_arn : null
}

output "artifacts_bucket_name" {
  description = "Artifacts S3 bucket name"
  value       = module.storage.artifacts_bucket_name
}

output "backups_bucket_name" {
  description = "Backups S3 bucket name"
  value       = module.storage.backups_bucket_name
}

output "logs_bucket_name" {
  description = "Logs S3 bucket name"
  value       = module.storage.logs_bucket_name
}

output "ml_models_bucket_name" {
  description = "ML models S3 bucket name"
  value       = module.storage.ml_models_bucket_name
}

output "model_artifacts_bucket_name" {
  description = "AI model artifacts bucket name"
  value       = module.ai_infra.model_artifacts_bucket_name
}

output "critical_alerts_topic_arn" {
  description = "SNS topic ARN for critical alerts"
  value       = module.monitoring.critical_alerts_topic_arn
}

output "warning_alerts_topic_arn" {
  description = "SNS topic ARN for warning alerts"
  value       = module.monitoring.warning_alerts_topic_arn
}

output "info_alerts_topic_arn" {
  description = "SNS topic ARN for info alerts"
  value       = module.monitoring.info_alerts_topic_arn
}
