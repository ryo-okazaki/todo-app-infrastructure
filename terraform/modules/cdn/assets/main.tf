# ------------------------------------------------------------------------------
# CloudFront Distribution: Static Assets
# ------------------------------------------------------------------------------
resource "aws_cloudfront_distribution" "static_assets" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Static Assets Distribution"
  default_root_object = "index.html"
  price_class         = "PriceClass_200" # 北米、欧州、アジア、中東、アフリカ
  aliases             = [local.static_assets_domain]

  # S3オリジン
  origin {
    domain_name = aws_s3_bucket.static_assets.bucket_regional_domain_name
    origin_id   = "S3-StaticAssets"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.static_assets.cloudfront_access_identity_path
    }

    # カスタムヘッダー
    custom_header {
      name  = "X-Origin-Verify"
      value = "static-assets"
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-StaticAssets"

    forwarded_values {
      query_string = false
      headers      = ["Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400    # 1日
    max_ttl                = 31536000 # 1年
    compress               = true

    # レスポンスヘッダーポリシー
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id
  }

  # /_next/static/* 用の特別なキャッシュ設定（immutable）
  ordered_cache_behavior {
    path_pattern     = "/_next/static/*"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-StaticAssets"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 31536000 # 1年
    default_ttl            = 31536000
    max_ttl                = 31536000
    compress               = true

    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id
  }

  # SSL証明書設定
  viewer_certificate {
    acm_certificate_arn      = var.cloudfront_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # Geo制限（必要に応じて）
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # ログ設定
  logging_config {
    include_cookies = false
    bucket          = "${var.logs_bucket_id}.s3.amazonaws.com"
    prefix          = "cloudfront/static-assets/"
  }

  # WAF設定（オプション）
  web_acl_id = var.enable_waf ? var.waf_web_acl_id : null

  tags = {
    Name        = "-static-assets-cdn"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# CloudFront Distribution: Media
# ------------------------------------------------------------------------------
resource "aws_cloudfront_distribution" "media" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "Media Distribution"
  price_class     = "PriceClass_200"
  aliases         = [local.media_domain]

  # S3オリジン
  origin {
    domain_name = aws_s3_bucket.media.bucket_regional_domain_name
    origin_id   = "S3-UserImages"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.media.cloudfront_access_identity_path
    }

    custom_header {
      name  = "X-Origin-Verify"
      value = "user-images"
    }
  }

  # デフォルトキャッシュビヘイビア
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-UserImages"

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400 # 1日（更新可能性を考慮）
    max_ttl                = 31536000
    compress               = true

    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id
  }

  # SSL証明書設定
  viewer_certificate {
    acm_certificate_arn      = var.cloudfront_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # Geo制限
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # ログ設定
  logging_config {
    include_cookies = false
    bucket          = "${var.logs_bucket_id}.s3.amazonaws.com"
    prefix          = "cloudfront/user-images/"
  }

  # WAF設定（オプション）
  web_acl_id = var.enable_waf ? var.waf_web_acl_id : null

  tags = {
    Name        = "media-cdn"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# CloudFront Response Headers Policy (セキュリティヘッダー)
# ------------------------------------------------------------------------------
resource "aws_cloudfront_response_headers_policy" "security_headers" {
  name    = "security-headers-${var.environment}"
  comment = "Security headers policy for ${var.environment} environment"

  # CORS設定
  cors_config {
    access_control_allow_credentials = false

    access_control_allow_headers {
      items = ["*"]
    }

    access_control_allow_methods {
      items = ["GET", "HEAD", "OPTIONS"]
    }

    access_control_allow_origins {
      items = ["*"]
    }

    access_control_max_age_sec = 3600
    origin_override            = false
  }

  # セキュリティヘッダー
  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
  }
}
