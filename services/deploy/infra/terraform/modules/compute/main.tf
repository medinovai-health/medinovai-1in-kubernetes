data "aws_region" "current" {}

data "tls_certificate" "oidc" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}


locals {
  cluster_name = "${var.environment}-${var.project}-cluster"

  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project
  })
}

# Security group for cluster - allow 443 from VPC CIDR
resource "aws_security_group" "cluster" {
  name        = "${local.cluster_name}-sg"
  description = "Security group for EKS cluster API endpoint"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-sg"
  })
}

resource "aws_eks_cluster" "main" {
  name     = local.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = var.enable_public_endpoint
    security_group_ids      = [aws_security_group.cluster.id]
  }

  dynamic "encryption_config" {
    for_each = var.kms_key_arn != "" ? [1] : []
    content {
      provider {
        key_arn = var.kms_key_arn
      }
      resources = ["secrets"]
    }
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  tags = local.common_tags

  depends_on = [
    aws_security_group.cluster
  ]
}

resource "aws_eks_node_group" "general" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "general"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  instance_types = var.node_instance_types
  disk_size      = var.node_disk_size

  scaling_config {
    desired_size = var.desired_nodes
    max_size     = var.max_nodes
    min_size     = var.min_nodes
  }

  labels = {
    role        = "general"
    environment = var.environment
  }

  update_config {
    max_unavailable = 1
  }

  tags = local.common_tags

  depends_on = [
    aws_eks_cluster.main
  ]
}

resource "aws_eks_node_group" "gpu" {
  count = var.enable_gpu_nodes ? 1 : 0

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "gpu"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  instance_types = var.gpu_instance_types
  disk_size      = var.node_disk_size

  scaling_config {
    desired_size = var.gpu_desired_nodes
    max_size     = var.gpu_max_nodes
    min_size     = var.gpu_min_nodes
  }

  labels = {
    role        = "gpu"
    accelerator = "nvidia"
    environment = var.environment
  }

  taint {
    key    = "nvidia.com/gpu"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  update_config {
    max_unavailable = 1
  }

  tags = local.common_tags

  depends_on = [
    aws_eks_cluster.main
  ]
}

# EKS Addons
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "vpc-cni"
  addon_version               = null
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.general
  ]
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "coredns"
  addon_version               = null
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.general
  ]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "kube-proxy"
  addon_version               = null
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = null
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.general
  ]
}
