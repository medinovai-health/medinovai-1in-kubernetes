# -----------------------------------------------------------------------------
# RDS PostgreSQL - MedinovAI
# -----------------------------------------------------------------------------

resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-${var.environment}-db-subnet"
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_db_parameter_group" "main" {
  family = "postgres16"
  name   = "${var.project}-${var.environment}-db-params"

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  tags = var.tags
}

resource "aws_db_instance" "main" {
  identifier     = "${var.project}-${var.environment}-db"
  engine         = "postgres"
  engine_version = "16"

  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage

  max_allocated_storage = var.db_max_allocated_storage

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  parameter_group_name   = aws_db_parameter_group.main.name
  vpc_security_group_ids = [var.db_security_group_id]

  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  storage_encrypted = true
  kms_key_id        = var.kms_key_arn != "" ? var.kms_key_arn : null

  performance_insights_enabled = true
  deletion_protection          = var.environment == "production"

  skip_final_snapshot       = var.environment != "production"
  final_snapshot_identifier = var.environment == "production" ? "${var.project}-${var.environment}-db-final" : null

  tags = var.tags
}

# -----------------------------------------------------------------------------
# RDS Read Replica (optional)
# -----------------------------------------------------------------------------

resource "aws_db_instance" "read_replica" {
  count = var.create_read_replica ? 1 : 0

  identifier                   = "${var.project}-${var.environment}-db-replica"
  replicate_source_db          = aws_db_instance.main.identifier
  instance_class               = var.db_instance_class
  publicly_accessible          = false
  performance_insights_enabled = true
  deletion_protection          = var.environment == "production"
  skip_final_snapshot          = true
  vpc_security_group_ids       = [var.db_security_group_id]
  db_subnet_group_name         = aws_db_subnet_group.main.name

  tags = merge(var.tags, { Role = "read-replica" })
}

# -----------------------------------------------------------------------------
# ElastiCache Redis - MedinovAI
# -----------------------------------------------------------------------------

resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project}-${var.environment}-redis-subnet"
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_elasticache_parameter_group" "main" {
  family = "redis7"
  name   = "${var.project}-${var.environment}-redis-params"

  tags = var.tags
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.project}-${var.environment}-redis"
  description          = "MedinovAI Redis cache for ${var.environment}"

  engine         = "redis"
  engine_version = "7.0"

  node_type            = var.redis_node_type
  num_cache_clusters   = var.redis_num_nodes
  port                 = 6379
  parameter_group_name = aws_elasticache_parameter_group.main.name
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [var.redis_security_group_id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.redis_auth_token
  kms_key_id                 = var.kms_key_arn != "" ? var.kms_key_arn : null

  automatic_failover_enabled = var.redis_num_nodes > 1 ? true : false
  multi_az_enabled           = var.redis_num_nodes > 1 ? true : false

  tags = var.tags
}
