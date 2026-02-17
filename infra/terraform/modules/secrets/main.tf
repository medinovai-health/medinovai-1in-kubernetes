# ─── MedinovAI Secrets Module ──────────────────────────────────────────────────
# KMS encryption key and Secrets Manager secrets for the platform.

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  kms_alias  = "alias/medinovai/${var.environment}"
  common_tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
  })
}

# ─── KMS Key ───────────────────────────────────────────────────────────────────

resource "aws_kms_key" "secrets" {
  description             = "KMS key for MedinovAI secrets encryption in ${var.environment}"
  deletion_window_in_days = 30
  enable_key_rotation    = true

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "medinovai-secrets-kms-policy"
    Statement = concat(
      [
        {
          Sid    = "Enable IAM User Permissions"
          Effect = "Allow"
          Principal = {
            AWS = "arn:aws:iam::${local.account_id}:root"
          }
          Action   = "kms:*"
          Resource = "*"
        },
        {
          Sid    = "Allow Secrets Manager"
          Effect = "Allow"
          Principal = {
            Service = "secretsmanager.${var.region}.amazonaws.com"
          }
          Action = [
            "kms:Decrypt",
            "kms:GenerateDataKey"
          ]
          Resource = "*"
          Condition = {
            StringEquals = {
              "kms:ViaService" = "secretsmanager.${var.region}.amazonaws.com"
            }
          }
        }
      ],
      length(var.kms_allowed_role_arns) > 0 ? [
        {
          Sid    = "Allow IAM Roles"
          Effect = "Allow"
          Principal = {
            AWS = var.kms_allowed_role_arns
          }
          Action = [
            "kms:Decrypt",
            "kms:DescribeKey",
            "kms:CreateGrant"
          ]
          Resource = "*"
          Condition = {
            StringEquals = {
              "kms:ViaService" = "secretsmanager.${var.region}.amazonaws.com"
            }
          }
        }
      ] : []
    )
  })

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-secrets-kms" })
}

resource "aws_kms_alias" "secrets" {
  name          = local.kms_alias
  target_key_id = aws_kms_key.secrets.key_id
}

# ─── Secrets Manager Secrets ───────────────────────────────────────────────────

resource "aws_secretsmanager_secret" "database" {
  name                    = "${var.project}/${var.environment}/database/credentials"
  description             = "Database credentials for MedinovAI ${var.environment}"
  kms_key_id              = aws_kms_key.secrets.arn
  recovery_window_in_days = 30

  tags = merge(local.common_tags, { Name = "${var.project}/${var.environment}/database/credentials" })
}

resource "aws_secretsmanager_secret" "redis" {
  name                    = "${var.project}/${var.environment}/redis/credentials"
  description             = "Redis credentials for MedinovAI ${var.environment}"
  kms_key_id              = aws_kms_key.secrets.arn
  recovery_window_in_days = 30

  tags = merge(local.common_tags, { Name = "${var.project}/${var.environment}/redis/credentials" })
}

resource "aws_secretsmanager_secret" "jwt" {
  name                    = "${var.project}/${var.environment}/jwt/signing-key"
  description             = "JWT signing key for MedinovAI ${var.environment}"
  kms_key_id              = aws_kms_key.secrets.arn
  recovery_window_in_days = 30

  tags = merge(local.common_tags, { Name = "${var.project}/${var.environment}/jwt/signing-key" })
}

resource "aws_secretsmanager_secret" "api_keys" {
  name                    = "${var.project}/${var.environment}/api/keys"
  description             = "API keys for internal service-to-service auth"
  kms_key_id              = aws_kms_key.secrets.arn
  recovery_window_in_days = 30

  tags = merge(local.common_tags, { Name = "${var.project}/${var.environment}/api/keys" })
}

resource "aws_secretsmanager_secret" "encryption_keys" {
  name                    = "${var.project}/${var.environment}/encryption/keys"
  description             = "Encryption keys for MedinovAI ${var.environment}"
  kms_key_id              = aws_kms_key.secrets.arn
  recovery_window_in_days = 30

  tags = merge(local.common_tags, { Name = "${var.project}/${var.environment}/encryption/keys" })
}

# ─── Secret Rotation ───────────────────────────────────────────────────────────

resource "aws_secretsmanager_secret_rotation" "database" {
  count = var.enable_rotation && var.rotation_lambda_arn != "" ? 1 : 0

  secret_id           = aws_secretsmanager_secret.database.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }
}

resource "aws_secretsmanager_secret_rotation" "redis" {
  count = var.enable_rotation && var.rotation_lambda_arn != "" ? 1 : 0

  secret_id           = aws_secretsmanager_secret.redis.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }
}

resource "aws_secretsmanager_secret_rotation" "jwt" {
  count = var.enable_rotation && var.rotation_lambda_arn != "" ? 1 : 0

  secret_id           = aws_secretsmanager_secret.jwt.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }
}

resource "aws_secretsmanager_secret_rotation" "api_keys" {
  count = var.enable_rotation && var.rotation_lambda_arn != "" ? 1 : 0

  secret_id           = aws_secretsmanager_secret.api_keys.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }
}

resource "aws_secretsmanager_secret_rotation" "encryption_keys" {
  count = var.enable_rotation && var.rotation_lambda_arn != "" ? 1 : 0

  secret_id           = aws_secretsmanager_secret.encryption_keys.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }
}
