output "service_name" {
  description = "ECS Service name"
  value       = aws_ecs_service.this.name
}

output "service_id" {
  description = "ECS Service ID"
  value       = aws_ecs_service.this.id
}

output "task_definition_arn" {
  description = "Task Definition ARN"
  value       = aws_ecs_task_definition.this.arn
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.this.id
}

output "target_group_arn" {
  description = "Target Group ARN"
  value       = aws_lb_target_group.this.arn
}
