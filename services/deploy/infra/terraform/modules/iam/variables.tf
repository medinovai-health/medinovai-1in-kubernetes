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

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "eks_oidc_issuer_url" {
  description = "EKS OIDC issuer URL for IRSA"
  type        = string
  default     = ""
}

variable "eks_oidc_thumbprint" {
  description = "EKS OIDC thumbprint"
  type        = string
  default     = ""
}

variable "kms_key_arn" {
  description = "KMS key ARN for secret decryption"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
