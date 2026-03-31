# -----------------------------------------------------------------------------
# AI Infrastructure Module Variables - MedinovAI
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

variable "kms_key_arn" {
  description = "ARN of the KMS key for encryption. Empty string uses AWS default."
  type        = string
  default     = ""
}

variable "enable_sagemaker" {
  description = "Enable SageMaker endpoint for model serving"
  type        = bool
  default     = false
}

variable "sagemaker_instance_type" {
  description = "SageMaker endpoint instance type"
  type        = string
  default     = "ml.g5.xlarge"
}

variable "sagemaker_instance_count" {
  description = "Number of instances for the SageMaker endpoint"
  type        = number
  default     = 1
}
