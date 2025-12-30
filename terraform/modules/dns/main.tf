terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.virginia, aws.dns_account]
    }
  }
}

# ------------------------------------------------------------------------------
# Route53 Hosted Zone
# ------------------------------------------------------------------------------
resource "aws_route53_zone" "this" {
  name = var.domain_name
  tags = {
    Name = var.domain_name
  }
}

# ------------------------------------------------------------------------------
# 1. ACM for ALB (Regional: Tokyo)
# ------------------------------------------------------------------------------
resource "aws_acm_certificate" "alb" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.domain_name}-alb-cert"
  }
}

# ------------------------------------------------------------------------------
# 2. ACM for CloudFront (Global: Virginia)
# ------------------------------------------------------------------------------
resource "aws_acm_certificate" "cloudfront" {
  provider = aws.virginia

  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.domain_name}-cloudfront-cert"
  }
}

# ------------------------------------------------------------------------------
# DNS Validation Records (両証明書を統合)
# ------------------------------------------------------------------------------
locals {
  # ALBとCloudFrontの検証レコードを統合（重複排除）
  validation_records = merge(
    {
      for dvo in aws_acm_certificate.alb.domain_validation_options : dvo.domain_name => {
        name   = dvo.resource_record_name
        record = dvo.resource_record_value
        type   = dvo.resource_record_type
      }
    },
    {
      for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
        name   = dvo.resource_record_name
        record = dvo.resource_record_value
        type   = dvo.resource_record_type
      }
    }
  )
}

resource "aws_route53_record" "validation" {
  for_each = local.validation_records

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.this.zone_id
}

# ------------------------------------------------------------------------------
# Validation Waiter
# ------------------------------------------------------------------------------
resource "aws_acm_certificate_validation" "alb" {
  certificate_arn         = aws_acm_certificate.alb.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider                = aws.virginia
  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

# ------------------------------------------------------------------------------
# DNS Delegation
# ------------------------------------------------------------------------------
resource "aws_route53_record" "delegation" {
  provider = aws.dns_account

  allow_overwrite = true
  name            = var.domain_name
  ttl             = 300
  type            = "NS"
  zone_id         = var.parent_zone_id

  records = aws_route53_zone.this.name_servers
}
