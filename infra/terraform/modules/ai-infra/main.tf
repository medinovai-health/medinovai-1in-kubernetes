# -----------------------------------------------------------------------------
# AI/ML Infrastructure Module - MedinovAI
# -----------------------------------------------------------------------------
# S3 model artifacts, ECR for ML images, optional SageMaker endpoint.
# -----------------------------------------------------------------------------

locals {
  common_tags = merge(var.tags, {
    Module    = "ai-infra"
    Terraform = "true"
  })
}

# -----------------------------------------------------------------------------
# S3 Bucket - Model artifacts
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "model_artifacts" {
  bucket = "${var.project}-${var.environment}-model-artifacts"

  tags = merge(local.common_tags, {
    Name    = "${var.project}-${var.environment}-model-artifacts"
    Purpose = "AI/ML model artifacts"
  })
}

resource "aws_s3_bucket_versioning" "model_artifacts" {
  bucket = aws_s3_bucket.model_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "model_artifacts" {
  bucket = aws_s3_bucket.model_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != "" ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn != "" ? var.kms_key_arn : null
    }
    bucket_key_enabled = var.kms_key_arn != "" ? true : null
  }
}

resource "aws_s3_bucket_public_access_block" "model_artifacts" {
  bucket = aws_s3_bucket.model_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# ECR Repository - ML model container images
# -----------------------------------------------------------------------------

resource "aws_ecr_repository" "ml_models" {
  name                 = "${var.project}/${var.environment}/ml-models"
  image_tag_mutability  = "MUTABLE"
  force_delete         = var.environment != "production"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = var.kms_key_arn != "" ? "KMS" : "AES256"
    kms_key         = var.kms_key_arn != "" ? var.kms_key_arn : null
  }

  tags = merge(local.common_tags, {
    Name    = "${var.project}-${var.environment}-ml-models"
    Purpose = "ML model container images"
  })
}

resource "aws_ecr_lifecycle_policy" "ml_models" {
  repository = aws_ecr_repository.ml_models.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 30 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group - Inference logs
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "inference" {
  name              = "/medinovai/${var.environment}/ai-inference"
  retention_in_days  = 30
  tags              = merge(local.common_tags, { Purpose = "Inference logs" })
}

# -----------------------------------------------------------------------------
# SageMaker - Optional endpoint (when enable_sagemaker is true)
# -----------------------------------------------------------------------------

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "sagemaker" {
  count = var.enable_sagemaker ? 1 : 0

  name = "${var.project}-${var.environment}-sagemaker-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, { Purpose = "SageMaker execution" })
}

resource "aws_iam_role_policy_attachment" "sagemaker_full" {
  count = var.enable_sagemaker ? 1 : 0

  role       = aws_iam_role.sagemaker[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_s3_object" "model_placeholder" {
  count = var.enable_sagemaker ? 1 : 0

  bucket  = aws_s3_bucket.model_artifacts.id
  key     = "models/placeholder/model.tar.gz"
  content = ""
}

resource "aws_sagemaker_model" "main" {
  count = var.enable_sagemaker ? 1 : 0

  name               = "${var.project}-${var.environment}-ml-model"
  execution_role_arn = aws_iam_role.sagemaker[0].arn

  primary_container {
    image          = "763104351884.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/pytorch-inference-gpu:2.0.0-gpu-py310"
    model_data_url = "s3://${aws_s3_bucket.model_artifacts.bucket}/${aws_s3_object.model_placeholder[0].key}"
  }

  tags = local.common_tags
}

resource "aws_sagemaker_endpoint_configuration" "main" {
  count = var.enable_sagemaker ? 1 : 0

  name = "${var.project}-${var.environment}-ml-endpoint-config"

  production_variants {
    variant_name           = "primary"
    model_name             = aws_sagemaker_model.main[0].name
    instance_type          = var.sagemaker_instance_type
    initial_instance_count = var.sagemaker_instance_count
  }
}

resource "aws_sagemaker_endpoint" "main" {
  count = var.enable_sagemaker ? 1 : 0

  name                 = "${var.project}-${var.environment}-ml-endpoint"
  endpoint_config_name  = aws_sagemaker_endpoint_configuration.main[0].name

  tags = local.common_tags
}
