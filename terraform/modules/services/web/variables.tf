variable "env" {
  description = "Environment (e.g., development, staging, production)"
  type        = string
}

variable "name" {
  description = "Service name (e.g., todo-app-dev-frontend)"
  type        = string
}

variable "cluster_id" {
  description = "ECS Cluster ID"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ALB Security Group ID"
  type        = string
}

variable "https_listener_arn" {
  description = "HTTPS Listener ARN"
  type        = string
}

variable "listener_rule_priority" {
  description = "Listener rule priority"
  type        = number
}

variable "path_pattern" {
  description = "Path pattern for routing"
  type        = list(string)
  default     = ["/*"]
}

variable "service_connect_namespace_arn" {
  description = "Service Connect namespace ARN"
  type        = string
}

variable "ecr_repository_url" {
  description = "ECR repository URL"
  type        = string
}

variable "container_port" {
  description = "Container port"
  type        = number
}

variable "cpu" {
  description = "CPU units for Fargate task"
  type        = number
  default     = 512
}

variable "memory" {
  description = "Memory (MiB) for Fargate task"
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 2
}

variable "environment_variables" {
  description = "Environment variables for container"
  type        = map(string)
  default     = {}
}

variable "secret_environment_variables" {
  description = "Secret environment variables for container"
  type        = map(string)
  default     = {}
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/health"
}

variable "health_check_matcher" {
  description = "HTTP status code for healthy response"
  type        = string
  default     = "200"
}

variable "deregistration_delay" {
  description = "Target group deregistration delay"
  type        = number
  default     = 30
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}
