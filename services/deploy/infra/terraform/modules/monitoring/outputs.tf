# -----------------------------------------------------------------------------
# Monitoring Module Outputs - MedinovAI
# -----------------------------------------------------------------------------

output "critical_alerts_topic_arn" {
  description = "ARN of the SNS topic for P1 critical alerts"
  value       = aws_sns_topic.critical_alerts.arn
}

output "warning_alerts_topic_arn" {
  description = "ARN of the SNS topic for P2-P3 warning alerts"
  value       = aws_sns_topic.warning_alerts.arn
}

output "info_alerts_topic_arn" {
  description = "ARN of the SNS topic for P4 info alerts"
  value       = aws_sns_topic.info_alerts.arn
}

output "log_group_names" {
  description = "Map of service names to CloudWatch log group names"
  value       = { for k, v in aws_cloudwatch_log_group.services : k => v.name }
}

output "dashboard_arn" {
  description = "ARN of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_arn
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "datadog_role_arn" {
  description = "ARN of the IAM role for Datadog integration (when enabled)"
  value       = var.enable_datadog ? aws_iam_role.datadog[0].arn : null
}
