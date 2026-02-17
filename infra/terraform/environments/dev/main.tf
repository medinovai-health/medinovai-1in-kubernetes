# -----------------------------------------------------------------------------
# MedinovAI Dev Environment - Module Composition
# -----------------------------------------------------------------------------
# Wires all 9 modules in dependency order.
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  account_id           = data.aws_caller_identity.current.account_id
  region               = data.aws_region.current.name
  availability_zones   = slice(data.aws_availability_zones.available.names, 0, 2)
}

# -----------------------------------------------------------------------------
# 1. Networking - VPC, subnets
# -----------------------------------------------------------------------------
module "networking" {
  source = "../../modules/networking"

  environment        = var.environment
  project            = var.project
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = local.availability_zones
  enable_nat_gateway = true
  enable_flow_logs   = false
  tags               = var.tags
}

# -----------------------------------------------------------------------------
# 2. IAM - Roles, policies (OIDC provider created on second apply after EKS exists)
# -----------------------------------------------------------------------------
module "iam" {
  source = "../../modules/iam"

  environment          = var.environment
  project               = var.project
  region                = local.region
  account_id            = local.account_id
  kms_key_arn          = module.secrets.kms_key_arn
  eks_oidc_issuer_url  = ""
  eks_oidc_thumbprint  = ""
  tags                  = var.tags
}

# -----------------------------------------------------------------------------
# 3. Secrets - KMS, Secrets Manager
# -----------------------------------------------------------------------------
module "secrets" {
  source = "../../modules/secrets"

  environment   = var.environment
  project       = var.project
  region        = local.region
  tags          = var.tags
}

# -----------------------------------------------------------------------------
# 4. DNS - Route53, ACM (optional, when domain_name is set)
# -----------------------------------------------------------------------------
module "dns" {
  count  = var.domain_name != "" ? 1 : 0
  source = "../../modules/dns"

  environment = var.environment
  project     = var.project
  domain_name = var.domain_name
  tags        = var.tags
}

# -----------------------------------------------------------------------------
# Database tier security groups (allow access from VPC)
# -----------------------------------------------------------------------------
resource "aws_security_group" "db" {
  name        = "${var.project}-${var.environment}-db-sg"
  description = "PostgreSQL access from VPC"
  vpc_id      = module.networking.vpc_id

  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [module.networking.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-db-sg" })
}

resource "aws_security_group" "redis" {
  name        = "${var.project}-${var.environment}-redis-sg"
  description = "Redis access from VPC"
  vpc_id      = module.networking.vpc_id

  ingress {
    description = "Redis from VPC"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [module.networking.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-redis-sg" })
}

# -----------------------------------------------------------------------------
# 5. Storage - S3 buckets
# -----------------------------------------------------------------------------
module "storage" {
  source = "../../modules/storage"

  environment   = var.environment
  project       = var.project
  kms_key_arn   = module.secrets.kms_key_arn
  tags          = var.tags
}

# -----------------------------------------------------------------------------
# 6. Database - RDS, Redis
# -----------------------------------------------------------------------------
module "database" {
  source = "../../modules/database"

  environment               = var.environment
  project                   = var.project
  subnet_ids                = module.networking.data_subnet_ids
  db_security_group_id      = aws_security_group.db.id
  redis_security_group_id   = aws_security_group.redis.id
  kms_key_arn               = module.secrets.kms_key_arn
  db_instance_class         = var.db_instance_class
  db_password               = var.db_password
  multi_az                  = var.multi_az
  backup_retention_period   = var.backup_retention
  create_read_replica       = var.create_read_replica
  redis_node_type           = var.redis_node_type
  redis_auth_token          = var.redis_auth_token
  tags                      = var.tags
}

# -----------------------------------------------------------------------------
# 7. Compute - EKS cluster
# -----------------------------------------------------------------------------
module "compute" {
  source = "../../modules/compute"

  environment         = var.environment
  project             = var.project
  vpc_id              = module.networking.vpc_id
  vpc_cidr            = module.networking.vpc_cidr
  subnet_ids          = module.networking.private_subnet_ids
  cluster_role_arn    = module.iam.eks_cluster_role_arn
  node_role_arn       = module.iam.eks_nodes_role_arn
  kms_key_arn         = module.secrets.kms_key_arn
  min_nodes           = var.min_nodes
  max_nodes           = var.max_nodes
  desired_nodes       = var.min_nodes
  enable_gpu_nodes    = var.enable_gpu_nodes
  gpu_min_nodes       = var.enable_gpu_nodes ? 1 : 0
  gpu_max_nodes       = var.enable_gpu_nodes ? 2 : 0
  gpu_desired_nodes   = var.enable_gpu_nodes ? 1 : 0
  tags                = var.tags
}

# -----------------------------------------------------------------------------
# 8. Monitoring - CloudWatch, SNS
# -----------------------------------------------------------------------------
module "monitoring" {
  source = "../../modules/monitoring"

  environment       = var.environment
  project           = var.project
  eks_cluster_name  = module.compute.cluster_name
  tags              = var.tags
}

# -----------------------------------------------------------------------------
# 9. AI Infra - ECR, model storage
# -----------------------------------------------------------------------------
module "ai_infra" {
  source = "../../modules/ai-infra"

  environment   = var.environment
  project       = var.project
  kms_key_arn   = module.secrets.kms_key_arn
  tags          = var.tags
}
