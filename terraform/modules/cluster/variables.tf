variable "env" {
  description = "Environment (e.g., dev, prod)"
  type        = string
}

variable "name" {
  description = "ECS Cluster name"
  type        = string
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
