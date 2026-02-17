output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_nodes_role_arn" {
  description = "ARN of the EKS node group IAM role"
  value       = aws_iam_role.eks_nodes.arn
}

output "secrets_read_policy_arn" {
  description = "ARN of the secrets read policy"
  value       = aws_iam_policy.secrets_read.arn
}

output "s3_artifacts_policy_arn" {
  description = "ARN of the S3 artifacts policy"
  value       = aws_iam_policy.s3_artifacts.arn
}

output "cloudwatch_logs_policy_arn" {
  description = "ARN of the CloudWatch logs policy"
  value       = aws_iam_policy.cloudwatch_logs.arn
}

output "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider"
  value       = length(aws_iam_openid_connect_provider.eks) > 0 ? aws_iam_openid_connect_provider.eks[0].arn : ""
}
