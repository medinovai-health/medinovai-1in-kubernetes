# -----------------------------------------------------------------------------
# Database Module Outputs - MedinovAI
# -----------------------------------------------------------------------------

output "db_endpoint" {
  description = "RDS instance endpoint (hostname)"
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Name of the default database"
  value       = aws_db_instance.main.db_name
}

output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.main.id
}

output "db_arn" {
  description = "ARN of the RDS instance"
  value       = aws_db_instance.main.arn
}

output "read_replica_endpoint" {
  description = "RDS read replica endpoint (when created)"
  value       = var.create_read_replica ? aws_db_instance.read_replica[0].address : null
}

output "redis_endpoint" {
  description = "ElastiCache Redis primary endpoint"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "redis_port" {
  description = "ElastiCache Redis port"
  value       = aws_elasticache_replication_group.main.port
}

output "redis_primary_endpoint" {
  description = "ElastiCache Redis primary endpoint address"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "redis_reader_endpoint" {
  description = "ElastiCache Redis reader endpoint (for read replicas)"
  value       = aws_elasticache_replication_group.main.reader_endpoint_address
}

output "redis_replication_group_id" {
  description = "ElastiCache replication group ID"
  value       = aws_elasticache_replication_group.main.replication_group_id
}
