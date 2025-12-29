# ------------------------------------------------------------------------------
# CloudFront Distribution for SSR Application (Next.js)
# ------------------------------------------------------------------------------

locals {
  origin_id = "${var.name}-alb-origin"
}

# ------------------------------------------------------------------------------
# Origin Access Control is not used for ALB origins
# ALB uses custom header verification instead
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Cache Policy: Disabled (for SSR)
# ------------------------------------------------------------------------------
resource "aws_cloudfront_cache_policy" "ssr" {
  name        = "${var.name}-ssr-cache-policy"
  comment     = "Cache policy for SSR application - minimal caching"
  default_ttl = var.default_ttl
  max_ttl     = var.max_ttl
  min_ttl     = var.min_ttl

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "all"
    }

    headers_config {
      header_behavior = "whitelist"
      headers {
        items = [
          "Host",
          "Accept-Language",
          "Authorization",
        ]
      }
    }

    query_strings_config {
      query_string_behavior = "all"
    }

    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

# ------------------------------------------------------------------------------
# Origin Request Policy: All Viewer Except Host Header
# ------------------------------------------------------------------------------
resource "aws_cloudfront_origin_request_policy" "ssr" {
  name    = "${var.name}-ssr-origin-request-policy"
  comment = "Origin request policy for SSR application"

  cookies_config {
    cookie_behavior = "all"
  }

  headers_config {
    header_behavior = "allViewerAndWhitelistCloudFront"
    headers {
      items = [
        "CloudFront-Forwarded-Proto",
        "CloudFront-Is-Desktop-Viewer",
        "CloudFront-Is-Mobile-Viewer",
        "CloudFront-Is-Tablet-Viewer",
      ]
    }
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}

# ------------------------------------------------------------------------------
# Response Headers Policy
# ------------------------------------------------------------------------------
resource "aws_cloudfront_response_headers_policy" "security" {
  name    = "${var.name}-security-headers-policy"
  comment = "Security headers for SSR application"

  security_headers_config {
    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }

    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }
  }
}

# ------------------------------------------------------------------------------
# CloudFront Distribution
# ------------------------------------------------------------------------------
resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.name} SSR Application"
  default_root_object = ""
  price_class         = var.price_class
  aliases             = [var.domain_name]
  web_acl_id          = var.enable_waf ? var.waf_web_acl_arn : null

  # ------------------------------------------------------------------------------
  # Origin: ALB
  # ------------------------------------------------------------------------------
  origin {
    domain_name = var.alb_domain_name
    origin_id   = local.origin_id

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "https-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_read_timeout      = 60
      origin_keepalive_timeout = 60
    }

    # Custom header for origin verification
    # ALB listener rule should validate this header
    custom_header {
      name  = var.origin_custom_header_name
      value = var.origin_custom_header_value
    }
  }

  # ------------------------------------------------------------------------------
  # Default Cache Behavior (SSR)
  # ------------------------------------------------------------------------------
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.origin_id

    cache_policy_id            = aws_cloudfront_cache_policy.ssr.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.ssr.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  # ------------------------------------------------------------------------------
  # Cache Behavior: Static Assets (_next/static/*)
  # ------------------------------------------------------------------------------
  ordered_cache_behavior {
    path_pattern     = "_next/static/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.origin_id

    # Use AWS managed CachingOptimized policy for static assets
    cache_policy_id          = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized
    origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf" # CORS-S3Origin

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  # ------------------------------------------------------------------------------
  # Cache Behavior: Public Assets (public/*)
  # ------------------------------------------------------------------------------
  ordered_cache_behavior {
    path_pattern     = "public/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.origin_id

    cache_policy_id          = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized
    origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf" # CORS-S3Origin

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  # ------------------------------------------------------------------------------
  # SSL Certificate
  # ------------------------------------------------------------------------------
  viewer_certificate {
    acm_certificate_arn            = var.acm_certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
    cloudfront_default_certificate = false
  }

  # ------------------------------------------------------------------------------
  # Restrictions
  # ------------------------------------------------------------------------------
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # ------------------------------------------------------------------------------
  # Logging (Optional - uncomment if needed)
  # ------------------------------------------------------------------------------
  # logging_config {
  #   include_cookies = false
  #   bucket          = var.logging_bucket
  #   prefix          = "cloudfront/${var.name}/"
  # }

  tags = {
    Name = "${var.name}-distribution"
  }
}

# ------------------------------------------------------------------------------
# Route53 Record: CloudFront Alias
# ------------------------------------------------------------------------------
resource "aws_route53_record" "cloudfront" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cloudfront_ipv6" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}
