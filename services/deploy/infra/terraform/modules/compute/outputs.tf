output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster API server"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_certificate_authority" {
  description = "Base64 encoded certificate data for the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group ID associated with the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_additional_security_group_id" {
  description = "ID of the custom security group for the cluster (443 from VPC CIDR)"
  value       = aws_security_group.cluster.id
}

output "oidc_issuer_url" {
  description = "URL of the OIDC issuer for the cluster"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "oidc_issuer_thumbprint" {
  description = "Thumbprint of the OIDC issuer certificate"
  value       = data.tls_certificate.oidc.certificates[0].sha1_fingerprint
}

output "general_node_group_arn" {
  description = "ARN of the general node group"
  value       = aws_eks_node_group.general.arn
}

output "gpu_node_group_arn" {
  description = "ARN of the GPU node group (null if disabled)"
  value       = var.enable_gpu_nodes ? aws_eks_node_group.gpu[0].arn : null
}

output "kubeconfig_command" {
  description = "Command to configure kubectl for the cluster"
  value       = "aws eks update-kubeconfig --region ${data.aws_region.current.name} --name ${aws_eks_cluster.main.name}"
}
