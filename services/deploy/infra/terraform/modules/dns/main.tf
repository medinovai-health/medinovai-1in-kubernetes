locals {
  base_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project
    Module      = "dns"
  })

  wildcard_domain = "*.${var.domain_name}"
  cert_sans       = concat([var.domain_name, local.wildcard_domain], var.subject_alternative_names)
}

# -----------------------------------------------------------------------------
# Route53 Hosted Zone
# -----------------------------------------------------------------------------

resource "aws_route53_zone" "main" {
  name    = var.domain_name
  comment = "Managed by Terraform - ${var.project}"

  tags = local.base_tags
}

# -----------------------------------------------------------------------------
# ACM Certificate (primary domain + wildcard + custom SANs)
# -----------------------------------------------------------------------------

resource "aws_acm_certificate" "main" {
  domain_name               = var.domain_name
  subject_alternative_names  = distinct([for d in local.cert_sans : d if d != var.domain_name])
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = local.base_tags
}

# -----------------------------------------------------------------------------
# ACM DNS Validation Records
# -----------------------------------------------------------------------------

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

# -----------------------------------------------------------------------------
# ACM Certificate Validation (wait for DNS validation to complete)
# -----------------------------------------------------------------------------

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# -----------------------------------------------------------------------------
# Route53 Health Check (optional)
# -----------------------------------------------------------------------------

resource "aws_route53_health_check" "main" {
  count = var.enable_health_check ? 1 : 0

  fqdn              = var.domain_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  request_interval  = 30
  failure_threshold = 3

  measure_latency = true

  tags = local.base_tags
}

# -----------------------------------------------------------------------------
# Apex A Record (alias to ALB)
# -----------------------------------------------------------------------------

resource "aws_route53_record" "apex" {
  count = var.alb_dns_name != "" && var.alb_zone_id != "" ? 1 : 0

  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = var.enable_health_check
  }
}

# -----------------------------------------------------------------------------
# www CNAME Record (points to apex)
# -----------------------------------------------------------------------------

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.domain_name]
}
