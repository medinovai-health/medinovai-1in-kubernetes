# -----------------------------------------------------------------------------
# MedinovAI Environment Variables
# -----------------------------------------------------------------------------

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

variable "domain_name" {
  description = "Primary domain name for Route53/ACM. Leave empty to skip DNS module."
  type        = string
  default     = ""
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "redis_auth_token" {
  description = "Redis authentication token"
  type        = string
  sensitive   = true
}

variable "enable_gpu_nodes" {
  description = "Enable GPU node group for AI workloads"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "min_nodes" {
  description = "Minimum EKS node count"
  type        = number
}

variable "max_nodes" {
  description = "Maximum EKS node count"
  type        = number
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
}

variable "multi_az" {
  description = "Enable Multi-AZ for RDS"
  type        = bool
  default     = false
}

variable "create_read_replica" {
  description = "Create RDS read replica"
  type        = bool
  default     = false
}

variable "backup_retention" {
  description = "RDS backup retention days"
  type        = number
}
