variable "environment" {
  description = "Environment name (e.g. production, staging, development)"
  type        = string
}

variable "project" {
  description = "Project name for resource tagging"
  type        = string
}

variable "domain_name" {
  description = "Primary domain name for the hosted zone and certificates"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_health_check" {
  description = "Whether to create a Route53 health check for the primary domain"
  type        = bool
  default     = false
}

variable "alb_dns_name" {
  description = "ALB DNS name for apex A record (leave empty to skip apex record)"
  type        = string
  default     = ""
}

variable "alb_zone_id" {
  description = "ALB hosted zone ID for apex A record alias (required if alb_dns_name is set)"
  type        = string
  default     = ""
}

variable "subject_alternative_names" {
  description = "Additional Subject Alternative Names for the ACM certificate"
  type        = list(string)
  default     = []
}
