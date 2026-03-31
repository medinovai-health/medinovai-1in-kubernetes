variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster (private subnets recommended)"
  type        = list(string)
}

variable "cluster_role_arn" {
  description = "IAM role ARN for the EKS cluster"
  type        = string
}

variable "node_role_arn" {
  description = "IAM role ARN for EKS node groups"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for EKS secrets encryption (optional)"
  type        = string
  default     = ""
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "node_instance_types" {
  description = "EC2 instance types for the general node group"
  type        = list(string)
  default     = ["m6i.large"]
}

variable "min_nodes" {
  description = "Minimum number of nodes in the general node group"
  type        = number
  default     = 2
}

variable "max_nodes" {
  description = "Maximum number of nodes in the general node group"
  type        = number
  default     = 10
}

variable "desired_nodes" {
  description = "Desired number of nodes in the general node group"
  type        = number
  default     = 2
}

variable "node_disk_size" {
  description = "Disk size in GB for nodes"
  type        = number
  default     = 50
}

variable "enable_gpu_nodes" {
  description = "Whether to create a GPU node group"
  type        = bool
  default     = false
}

variable "gpu_instance_types" {
  description = "EC2 instance types for the GPU node group"
  type        = list(string)
  default     = ["g5.xlarge"]
}

variable "gpu_min_nodes" {
  description = "Minimum number of nodes in the GPU node group"
  type        = number
  default     = 0
}

variable "gpu_max_nodes" {
  description = "Maximum number of nodes in the GPU node group"
  type        = number
  default     = 4
}

variable "gpu_desired_nodes" {
  description = "Desired number of nodes in the GPU node group"
  type        = number
  default     = 0
}

variable "enable_public_endpoint" {
  description = "Whether to enable public access to the EKS API endpoint"
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "VPC CIDR block for security group rules"
  type        = string
}
