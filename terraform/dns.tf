resource "aws_route53_zone" "application" {
  count = var.create_route53_zone ? 1 : 0

  name = var.application_domain

  tags = {
    Project     = "Argo-CD-EKS"
    Environment = "dev"
    Terraform   = "true"
  }
}

data "aws_route53_zone" "application" {
  count = var.create_route53_zone ? 0 : 1

  zone_id = var.route53_zone_id
}

locals {
  application_zone_id = var.create_route53_zone ? aws_route53_zone.application[0].zone_id : data.aws_route53_zone.application[0].zone_id
}

resource "aws_acm_certificate" "application" {
  domain_name       = var.application_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Project     = "Argo-CD-EKS"
    Environment = "dev"
    Terraform   = "true"
  }
}

resource "aws_route53_record" "application_validation" {
  for_each = {
    for option in aws_acm_certificate.application.domain_validation_options : option.domain_name => {
      name   = option.resource_record_name
      record = option.resource_record_value
      type   = option.resource_record_type
    }
  }

  zone_id         = local.application_zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "application" {
  certificate_arn         = aws_acm_certificate.application.arn
  validation_record_fqdns = [for record in aws_route53_record.application_validation : record.fqdn]
}