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

output "service_connect_dns_name" {
  description = "Service Connect DNS name"
  value       = "${var.service_connect_dns_name}.${split(":", var.service_connect_namespace_arn)[1]}"
}
