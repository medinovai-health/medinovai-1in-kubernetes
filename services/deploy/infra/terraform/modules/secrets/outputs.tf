output "kms_key_arn" {
  description = "ARN of the KMS key used for secrets encryption"
  value       = aws_kms_key.secrets.arn
}

output "kms_key_id" {
  description = "ID of the KMS key"
  value       = aws_kms_key.secrets.key_id
}

output "kms_alias_arn" {
  description = "ARN of the KMS key alias"
  value       = aws_kms_alias.secrets.arn
}

output "database_secret_arn" {
  description = "ARN of the database credentials secret"
  value       = aws_secretsmanager_secret.database.arn
}

output "redis_secret_arn" {
  description = "ARN of the Redis credentials secret"
  value       = aws_secretsmanager_secret.redis.arn
}

output "jwt_secret_arn" {
  description = "ARN of the JWT signing key secret"
  value       = aws_secretsmanager_secret.jwt.arn
}

output "api_keys_secret_arn" {
  description = "ARN of the API keys secret"
  value       = aws_secretsmanager_secret.api_keys.arn
}

output "encryption_key_secret_arn" {
  description = "ARN of the encryption keys secret"
  value       = aws_secretsmanager_secret.encryption_keys.arn
}

output "all_secret_arns" {
  description = "List of all secret ARNs"
  value = [
    aws_secretsmanager_secret.database.arn,
    aws_secretsmanager_secret.redis.arn,
    aws_secretsmanager_secret.jwt.arn,
    aws_secretsmanager_secret.api_keys.arn,
    aws_secretsmanager_secret.encryption_keys.arn,
  ]
}
