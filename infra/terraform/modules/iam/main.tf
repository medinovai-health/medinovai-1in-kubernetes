# ─── MedinovAI IAM Module ─────────────────────────────────────────────────────
# Service roles, policies, instance profiles, and OIDC for K8s.

# EKS cluster role
resource "aws_iam_role" "eks_cluster" {
  name = "${var.environment}-${var.project}-eks-cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })

  tags = merge(var.tags, { Name = "${var.environment}-${var.project}-eks-cluster" })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

# EKS node group role
resource "aws_iam_role" "eks_nodes" {
  name = "${var.environment}-${var.project}-eks-nodes"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = merge(var.tags, { Name = "${var.environment}-${var.project}-eks-nodes" })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "ssm_managed" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.eks_nodes.name
}

# OIDC provider for K8s service account IAM roles (IRSA)
resource "aws_iam_openid_connect_provider" "eks" {
  count = var.eks_oidc_issuer_url != "" ? 1 : 0

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.eks_oidc_thumbprint]
  url             = var.eks_oidc_issuer_url

  tags = merge(var.tags, { Name = "${var.environment}-${var.project}-eks-oidc" })
}

# Secrets Manager access policy for services
resource "aws_iam_policy" "secrets_read" {
  name        = "${var.environment}-${var.project}-secrets-read"
  description = "Read access to MedinovAI secrets in Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:${var.project}/${var.environment}/*"
    }, {
      Effect   = "Allow"
      Action   = ["kms:Decrypt"]
      Resource = var.kms_key_arn != "" ? [var.kms_key_arn] : ["*"]
      Condition = {
        StringEquals = {
          "kms:ViaService" = "secretsmanager.${var.region}.amazonaws.com"
        }
      }
    }]
  })

  tags = var.tags
}

# S3 access policy for backups and artifacts
resource "aws_iam_policy" "s3_artifacts" {
  name        = "${var.environment}-${var.project}-s3-artifacts"
  description = "Access to MedinovAI S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ]
      Resource = [
        "arn:aws:s3:::${var.project}-${var.environment}-*",
        "arn:aws:s3:::${var.project}-${var.environment}-*/*"
      ]
    }]
  })

  tags = var.tags
}

# CloudWatch logging policy
resource "aws_iam_policy" "cloudwatch_logs" {
  name        = "${var.environment}-${var.project}-cloudwatch-logs"
  description = "Write access to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "arn:aws:logs:${var.region}:${var.account_id}:log-group:/medinovai/${var.environment}/*"
    }]
  })

  tags = var.tags
}
