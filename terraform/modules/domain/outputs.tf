output "zone_id" {
  description = "Route53 Zone ID"
  value       = aws_route53_zone.this.zone_id
}

output "zone_name" {
  description = "Domain name"
  value       = aws_route53_zone.this.name
}

output "alb_certificate_arn" {
  description = "ACM Certificate ARN for ALB (Tokyo)"
  value       = aws_acm_certificate.alb.arn
}

output "cloudfront_certificate_arn" {
  description = "ACM Certificate ARN for CloudFront (Virginia)"
  value       = aws_acm_certificate.cloudfront.arn
}
