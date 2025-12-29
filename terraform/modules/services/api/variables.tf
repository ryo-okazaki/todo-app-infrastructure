variable "env" {
  description = "Environment (e.g., development, staging, production)"
  type        = string
}

variable "name" {
  description = "Service name (e.g., todo-app-dev-backend)"
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

variable "service_connect_namespace_arn" {
  description = "Service Connect namespace ARN"
  type        = string
}

variable "service_connect_dns_name" {
  description = "DNS name for Service Connect (e.g., backend)"
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
  default     = 256
}

variable "memory" {
  description = "Memory (MiB) for Fargate task"
  type        = number
  default     = 512
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

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "secrets_arns" {
  description = "List of Secrets Manager ARNs that the task execution role can access"
  type        = list(string)
  default     = []
}

variable "database_url_secret_arn" {
  description = "ARN of the DATABASE_URL secret in Secrets Manager"
  type        = string
  default     = null
}

variable "api_jwt_secret_arn" {
  description = "ARN of the API JWT secret in Secrets Manager"
  type        = string
  default     = null
}

# variable "db_credentials_secret_arn" {
#   description = "ARN of the database credentials secret in Secrets Manager (contains username, password, dbname, host, port as JSON)"
#   type        = string
#   default     = null
# }

variable "node_env" {
  description = "環境名 (例: development, staging, production)"
  type        = string
}
