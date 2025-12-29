# ------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------
output "alb_id" {
  description = "ALB ID"
  value       = aws_lb.this.id
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "ALB hosted zone ID"
  value       = aws_lb.this.zone_id
}

output "security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.this.id
}

output "http_listener_arn" {
  description = "HTTP listener ARN"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "HTTPS listener ARN"
  value       = aws_lb_listener.https.arn
}

output "cloudfront_validated_listener_rule_arn" {
  description = "CloudFront validated listener rule ARN"
  value       = try(aws_lb_listener_rule.cloudfront_validated[0].arn, null)
}
