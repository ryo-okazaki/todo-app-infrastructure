output "static_assets_bucket" {
  description = "Static assets S3 bucket info"
  value = {
    id                          = aws_s3_bucket.static_assets.id
    arn                         = aws_s3_bucket.static_assets.arn
    bucket_domain_name          = aws_s3_bucket.static_assets.bucket_domain_name
    bucket_regional_domain_name = aws_s3_bucket.static_assets.bucket_regional_domain_name
  }
}

output "media_bucket" {
  description = "media S3 bucket info"
  value = {
    id                          = aws_s3_bucket.media.id
    arn                         = aws_s3_bucket.media.arn
    bucket_domain_name          = aws_s3_bucket.media.bucket_domain_name
    bucket_regional_domain_name = aws_s3_bucket.media.bucket_regional_domain_name
  }
}

output "static_assets_cloudfront" {
  description = "Static assets CloudFront distribution info"
  value = {
    id             = aws_cloudfront_distribution.static_assets.id
    arn            = aws_cloudfront_distribution.static_assets.arn
    domain_name    = aws_cloudfront_distribution.static_assets.domain_name
    hosted_zone_id = aws_cloudfront_distribution.static_assets.hosted_zone_id
    custom_domain  = local.static_assets_domain
    url            = "https://${local.static_assets_domain}"
  }
}

output "media_cloudfront" {
  description = "media CloudFront distribution info"
  value = {
    id             = aws_cloudfront_distribution.media.id
    arn            = aws_cloudfront_distribution.media.arn
    domain_name    = aws_cloudfront_distribution.media.domain_name
    hosted_zone_id = aws_cloudfront_distribution.media.hosted_zone_id
    custom_domain  = local.media_domain
    url            = "https://${local.media_domain}"
  }
}

output "cloudfront_oai" {
  description = "CloudFront Origin Access Identity info"
  value = {
    static_assets = {
      id                              = aws_cloudfront_origin_access_identity.static_assets.id
      iam_arn                         = aws_cloudfront_origin_access_identity.static_assets.iam_arn
      cloudfront_access_identity_path = aws_cloudfront_origin_access_identity.static_assets.cloudfront_access_identity_path
    }
    media = {
      id                              = aws_cloudfront_origin_access_identity.media.id
      iam_arn                         = aws_cloudfront_origin_access_identity.media.iam_arn
      cloudfront_access_identity_path = aws_cloudfront_origin_access_identity.media.cloudfront_access_identity_path
    }
  }
}
