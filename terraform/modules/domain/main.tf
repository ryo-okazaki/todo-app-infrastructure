# ... 既存のterraformブロック ...
terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      # 【追加】dns_accountを受け取れるようにする
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
  domain_name       = var.domain_name
  subject_alternative_names = [
    "*.${var.domain_name}"  # *.dev.todo-app.ryo-okazaki.com
  ]
  validation_method = "DNS"

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
  provider = aws.virginia # バージニアリージョンを指定

  domain_name       = var.domain_name # Apexドメイン (またはワイルドカード)
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.domain_name}-cf-cert"
  }
}

# ------------------------------------------------------------------------------
# DNS Validation Records (Common Logic)
# ------------------------------------------------------------------------------
# 両方の証明書(ALB用, CF用)の検証用レコードを統合して作成
locals {
  # Set型をList型に変換してから結合する
  dvos = concat(
    tolist(aws_acm_certificate.alb.domain_validation_options),
    tolist(aws_acm_certificate.cloudfront.domain_validation_options)
  )
}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.alb.domain_validation_options : dvo.domain_name => {
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
  zone_id         = aws_route53_zone.this.zone_id
}

# ------------------------------------------------------------------------------
# Validation Waiter (検証完了までApplyを待機させる)
# ------------------------------------------------------------------------------
resource "aws_acm_certificate_validation" "alb" {
  certificate_arn         = aws_acm_certificate.alb.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider                = aws.virginia # ここもバージニア
  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

# ------------------------------------------------------------------------------
# DNS Delegation (別アカウントの親ゾーンにNSレコードを書く)
# ------------------------------------------------------------------------------
resource "aws_route53_record" "delegation" {
  provider = aws.dns_account # 別アカウントの権限を使用

  allow_overwrite = true
  name            = var.domain_name       # 例: dev.example.com
  ttl             = 300
  type            = "NS"
  zone_id         = var.parent_zone_id    # 親ゾーンID (例: example.comのID)

  records = [
    aws_route53_zone.this.name_servers[0],
    aws_route53_zone.this.name_servers[1],
    aws_route53_zone.this.name_servers[2],
    aws_route53_zone.this.name_servers[3],
  ]
}
