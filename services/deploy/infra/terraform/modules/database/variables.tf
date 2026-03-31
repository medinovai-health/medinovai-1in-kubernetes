# -----------------------------------------------------------------------------
# Database Module Variables - MedinovAI
# -----------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
}

variable "project" {
  description = "Project name (e.g., medinovai)"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the data tier (RDS and ElastiCache)"
  type        = list(string)
}

variable "db_security_group_id" {
  description = "Security group ID for the RDS instance"
  type        = string
}

variable "redis_security_group_id" {
  description = "Security group ID for the ElastiCache Redis cluster"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encryption. Empty string uses AWS default."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# RDS variables
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "Initial allocated storage for RDS (GB)"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for RDS autoscaling (GB)"
  type        = number
  default     = 100
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "medinovai"
}

variable "db_password" {
  description = "Master password for RDS"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Name of the default database to create"
  type        = string
  default     = "medinovai"
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain RDS backups"
  type        = number
  default     = 7
}

variable "create_read_replica" {
  description = "Create an RDS read replica"
  type        = bool
  default     = false
}

# ElastiCache variables
variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_num_nodes" {
  description = "Number of cache nodes in the Redis replication group"
  type        = number
  default     = 1
}

variable "redis_auth_token" {
  description = "Auth token for Redis (required when transit encryption is enabled)"
  type        = string
  sensitive   = true
}
