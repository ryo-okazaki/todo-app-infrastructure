# ------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------
output "distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.this.arn
}

output "distribution_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "distribution_hosted_zone_id" {
  description = "CloudFront distribution hosted zone ID"
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

output "domain_name" {
  description = "Custom domain name for CloudFront"
  value       = var.domain_name
}

output "origin_custom_header_name" {
  description = "Custom header name for origin verification"
  value       = var.origin_custom_header_name
}

output "origin_custom_header_value" {
  description = "Custom header value for origin verification"
  value       = var.origin_custom_header_value
  sensitive   = true
}
