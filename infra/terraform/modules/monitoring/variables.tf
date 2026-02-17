# -----------------------------------------------------------------------------
# Monitoring Module Variables - MedinovAI
# -----------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
}

variable "project" {
  description = "Project name (e.g., medinovai)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "Retention period for CloudWatch log groups (days)"
  type        = number
  default     = 30
}

variable "eks_cluster_name" {
  description = "EKS cluster name for metric alarms"
  type        = string
  default     = ""
}

variable "enable_datadog" {
  description = "Enable Datadog integration (IAM role for CloudWatch access)"
  type        = bool
  default     = false
}

variable "datadog_api_key" {
  description = "Datadog API key for integration (sensitive)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "pagerduty_endpoint" {
  description = "PagerDuty integration endpoint for critical alerts"
  type        = string
  default     = ""
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for alert notifications"
  type        = string
  sensitive   = true
  default     = ""
}
