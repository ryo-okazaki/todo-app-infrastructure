output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "ALB DNS Name (for Route53 Alias)"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "ALB Zone ID (for Route53 Alias)"
  value       = aws_lb.this.zone_id
}

output "https_listener_arn" {
  description = "HTTPS Listener ARN (for ECS listener rules)"
  value       = aws_lb_listener.https.arn
}

output "security_group_id" {
  description = "ALB Security Group ID (to allow traffic to ECS)"
  value       = aws_security_group.this.id
}
