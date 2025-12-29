# ------------------------------------------------------------------------------
# Local Variables for Domain Names
# ------------------------------------------------------------------------------
locals {
  static_assets_domain = "${var.static_assets_subdomain}.${var.domain_name}"
  media_domain         = "${var.media_subdomain}.${var.domain_name}"
}

# ------------------------------------------------------------------------------
# Route53 Records for CloudFront Distributions
# ------------------------------------------------------------------------------

# 静的アセット用のAレコード
resource "aws_route53_record" "static_assets_ipv4" {
  zone_id = var.route53_zone_id
  name    = local.static_assets_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.static_assets.domain_name
    zone_id                = aws_cloudfront_distribution.static_assets.hosted_zone_id
    evaluate_target_health = false
  }
}

# 静的アセット用のAAAAレコード（IPv6）
resource "aws_route53_record" "static_assets_ipv6" {
  zone_id = var.route53_zone_id
  name    = local.static_assets_domain
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.static_assets.domain_name
    zone_id                = aws_cloudfront_distribution.static_assets.hosted_zone_id
    evaluate_target_health = false
  }
}

# ユーザー画像用のAレコード
resource "aws_route53_record" "media_ipv4" {
  zone_id = var.route53_zone_id
  name    = local.media_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.media.domain_name
    zone_id                = aws_cloudfront_distribution.media.hosted_zone_id
    evaluate_target_health = false
  }
}

# ユーザー画像用のAAAAレコード（IPv6）
resource "aws_route53_record" "media_ipv6" {
  zone_id = var.route53_zone_id
  name    = local.media_domain
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.media.domain_name
    zone_id                = aws_cloudfront_distribution.media.hosted_zone_id
    evaluate_target_health = false
  }
}
