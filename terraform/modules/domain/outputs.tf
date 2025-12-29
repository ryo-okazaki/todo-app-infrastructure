output "zone_id" {
  description = "Route53 Hosted Zone ID"
  value       = aws_route53_zone.this.zone_id
}

output "zone_name_servers" {
  description = "Route53 Hosted Zone Name Servers"
  value       = aws_route53_zone.this.name_servers
}

output "alb_certificate_arn" {
  description = "ACM Certificate ARN for ALB (regional)"
  value       = aws_acm_certificate_validation.alb.certificate_arn
}

output "cloudfront_certificate_arn" {
  description = "ACM Certificate ARN for CloudFront (us-east-1)"
  value       = aws_acm_certificate_validation.cloudfront.certificate_arn
}

output "domain_name" {
  description = "Domain name"
  value       = var.domain_name
}

output "route53_zone_id" {
  description = "Route53 Hosted Zone ID"
  value       = aws_route53_zone.this.zone_id
}

output "route53_zone_name" {
  description = "Route53 Hosted Zone name"
  value       = aws_route53_zone.this.name
}

output "acm_alb_certificate_arn" {
  description = "ACM certificate ARN for ALB (Regional)"
  value       = aws_acm_certificate_validation.alb.certificate_arn
}

output "acm_cloudfront_certificate_arn" {
  description = "ACM certificate ARN for CloudFront (Virginia)"
  value       = aws_acm_certificate_validation.cloudfront.certificate_arn
}

output "name_servers" {
  description = "Name servers for the hosted zone"
  value       = aws_route53_zone.this.name_servers
}
