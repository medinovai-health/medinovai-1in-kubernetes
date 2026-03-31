variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "medinovai"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "kms_key_arn" {
  description = "KMS key ARN for server-side encryption. If empty, AES256 is used."
  type        = string
  default     = ""
}

variable "enable_replication" {
  description = "Enable cross-region replication for the backups bucket"
  type        = bool
  default     = false
}

variable "replication_region" {
  description = "AWS region for backup replication destination"
  type        = string
  default     = ""
}

variable "replica_bucket_arn" {
  description = "ARN of the destination bucket for replication. Required when enable_replication is true."
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "Number of days to retain logs before deletion"
  type        = number
  default     = 365
}

variable "backup_retention_days" {
  description = "Number of days to retain backups before transition to Glacier and expiration"
  type        = number
  default     = 90
}
