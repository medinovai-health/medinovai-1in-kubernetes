output "zone_id" {
  description = "Route53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "zone_name_servers" {
  description = "Route53 hosted zone name servers"
  value       = aws_route53_zone.main.name_servers
}

output "certificate_arn" {
  description = "ARN of the validated ACM certificate"
  value       = aws_acm_certificate_validation.main.certificate_arn
}

output "certificate_domain_name" {
  description = "Primary domain name of the ACM certificate"
  value       = aws_acm_certificate.main.domain_name
}

output "health_check_id" {
  description = "Route53 health check ID (empty if enable_health_check is false)"
  value       = var.enable_health_check ? aws_route53_health_check.main[0].id : ""
}
