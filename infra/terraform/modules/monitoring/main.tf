# -----------------------------------------------------------------------------
# Monitoring Module - CloudWatch, SNS, Alerting
# -----------------------------------------------------------------------------
# CloudWatch log groups, SNS topics, metric alarms, dashboard, optional Datadog.
# -----------------------------------------------------------------------------

locals {
  service_names = [
    "api-gateway",
    "auth-service",
    "clinical-engine",
    "data-pipeline",
    "ai-inference",
    "notification-service"
  ]
  common_tags = merge(var.tags, {
    Module    = "monitoring"
    Terraform = "true"
  })
}

# -----------------------------------------------------------------------------
# CloudWatch Log Groups - Per-service log groups
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "services" {
  for_each = toset(local.service_names)

  name              = "/medinovai/${var.environment}/${each.key}"
  retention_in_days = var.log_retention_days
  tags              = merge(local.common_tags, { Service = each.key })
}

# -----------------------------------------------------------------------------
# SNS Topics - Alert severity tiers
# -----------------------------------------------------------------------------

resource "aws_sns_topic" "critical_alerts" {
  name = "${var.project}-${var.environment}-critical-alerts"

  tags = merge(local.common_tags, {
    Name    = "${var.project}-${var.environment}-critical-alerts"
    Tier    = "P1"
    Purpose = "Critical alerts requiring immediate attention"
  })
}

resource "aws_sns_topic" "warning_alerts" {
  name = "${var.project}-${var.environment}-warning-alerts"

  tags = merge(local.common_tags, {
    Name    = "${var.project}-${var.environment}-warning-alerts"
    Tier    = "P2-P3"
    Purpose = "Warning alerts"
  })
}

resource "aws_sns_topic" "info_alerts" {
  name = "${var.project}-${var.environment}-info-alerts"

  tags = merge(local.common_tags, {
    Name    = "${var.project}-${var.environment}-info-alerts"
    Tier    = "P4"
    Purpose = "Informational alerts"
  })
}

# -----------------------------------------------------------------------------
# CloudWatch Metric Alarms - EKS cluster (only when eks_cluster_name is set)
# -----------------------------------------------------------------------------
# Uses Container Insights metrics. Enable CloudWatch Container Insights on EKS.
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "eks_high_cpu" {
  count = var.eks_cluster_name != "" ? 1 : 0

  alarm_name          = "${var.project}-${var.environment}-eks-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    ClusterName = var.eks_cluster_name
  }

  alarm_description = "EKS cluster CPU utilization exceeds 80%"
  alarm_actions      = [aws_sns_topic.critical_alerts.arn]

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "eks_high_memory" {
  count = var.eks_cluster_name != "" ? 1 : 0

  alarm_name          = "${var.project}-${var.environment}-eks-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "node_memory_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    ClusterName = var.eks_cluster_name
  }

  alarm_description = "EKS cluster memory utilization exceeds 80%"
  alarm_actions      = [aws_sns_topic.critical_alerts.arn]

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# CloudWatch Dashboard
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project}-${var.environment}-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "EKS Cluster CPU Utilization"
          region = data.aws_region.current.name
          metrics = var.eks_cluster_name != "" ? [
            ["ContainerInsights", "node_cpu_utilization", "ClusterName", var.eks_cluster_name, { stat = "Average", period = 300 }]
          ] : [
            ["AWS/EC2", "CPUUtilization", { stat = "Average", period = 300, label = "CPU (no EKS)" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "EKS Cluster Memory Utilization"
          region = data.aws_region.current.name
          metrics = var.eks_cluster_name != "" ? [
            ["ContainerInsights", "node_memory_utilization", "ClusterName", var.eks_cluster_name, { stat = "Average", period = 300 }]
          ] : [
            ["CWAgent", "mem_used_percent", { stat = "Average", period = 300, label = "Memory (no EKS)" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "EKS Cluster Network In"
          region = data.aws_region.current.name
          metrics = var.eks_cluster_name != "" ? [
            ["ContainerInsights", "node_network_total_bytes", "ClusterName", var.eks_cluster_name, { stat = "Sum", period = 300 }]
          ] : []
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Alarm Status"
          region = data.aws_region.current.name
          metrics = [
            ["AWS/CloudWatch", "AlarmTriggered", { stat = "Sum", period = 300 }]
          ]
        }
      }
    ]
  })
}

data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# Datadog Integration (IAM role for AWS integration)
# -----------------------------------------------------------------------------
# When enable_datadog is true, creates an IAM role that Datadog can assume
# to read CloudWatch logs and metrics. Configure the role ARN in Datadog.
# -----------------------------------------------------------------------------

resource "aws_iam_role" "datadog" {
  count = var.enable_datadog ? 1 : 0

  name = "${var.project}-${var.environment}-datadog-integration"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::464622532606:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.datadog_api_key
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, { Purpose = "Datadog CloudWatch integration" })
}

resource "aws_iam_role_policy" "datadog_cloudwatch" {
  count = var.enable_datadog ? 1 : 0

  name   = "datadog-cloudwatch-policy"
  role   = aws_iam_role.datadog[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:Get*",
          "cloudwatch:List*",
          "cloudwatch:Describe*",
          "logs:Get*",
          "logs:Describe*",
          "logs:FilterLogEvents",
          "logs:TestMetricFilter"
        ]
        Resource = "*"
      }
    ]
  })
}
