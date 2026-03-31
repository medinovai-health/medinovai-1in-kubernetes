variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "medinovai"
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "enable_rotation" {
  description = "Enable automatic secret rotation"
  type        = bool
  default     = false
}

variable "rotation_lambda_arn" {
  description = "ARN of the Lambda function used for secret rotation (required when enable_rotation is true)"
  type        = string
  default     = ""
}

variable "rotation_days" {
  description = "Number of days between automatic rotations"
  type        = number
  default     = 90
}

variable "kms_allowed_role_arns" {
  description = "List of IAM role ARNs allowed to use the KMS key for encryption/decryption"
  type        = list(string)
  default     = []
}
