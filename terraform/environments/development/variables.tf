variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
  default     = "todo-app"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string

  validation {
    condition     = var.vpc_cidr != null
    error_message = "vpc_cidr must be specified."
  }
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two availability zones must be specified."
  }
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.availability_zones)
    error_message = "The number of public_subnet_cidrs must match the number of availability_zones."
  }
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) == length(var.availability_zones)
    error_message = "The number of private_subnet_cidrs must match the number of availability_zones."
  }
}

variable "db_name" {
  description = "データベース名"
  type        = string
  sensitive   = true

  validation {
    condition     = var.db_name != null
    error_message = "db_name must be specified."
  }
}

variable "db_username" {
  description = "マスターユーザー名"
  type        = string
  sensitive   = true

  validation {
    condition     = var.db_username != null
    error_message = "db_username must be specified."
  }
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true

  validation {
    condition     = var.db_password != null
    error_message = "db_password must be specified."
  }
}

variable "db_port" {
  description = "RDS port number"
  type        = number

  validation {
    condition     = var.db_port != null
    error_message = "db_port must be specified."
  }
}

variable "domain_name" {
  description = "domain name for development environment"
  type        = string

  validation {
    condition     = var.domain_name != null
    error_message = "domain_name must be specified."
  }
}

variable "parent_zone_id" {
  description = "hosted zone ID of the parent domain"
  type        = string

  validation {
    condition     = var.parent_zone_id != null
    error_message = "parent_zone_id must be specified."
  }
}

variable "dns_account_assume_role" {
  description = "ARN of the role to assume for cross-account access"
  type        = string

  validation {
    condition     = var.dns_account_assume_role != null
    error_message = "dns_account_assume_role must be specified."
  }
}

variable "cloudfront_custom_header_name" {
  description = "Name of the custom header for CloudFront"
  type        = string
  default     = "X-CloudFront-Secret"
}

variable "api_container_port" {
  description = "Port number for the API container"
  type        = number

  validation {
    condition     = var.api_container_port != null
    error_message = "api_container_port must be specified."
  }
}

variable "web_container_port" {
  description = "Port number for the Web container"
  type        = number

  validation {
    condition     = var.web_container_port != null
    error_message = "web_container_port must be specified."
  }
}

variable "api_container_domain_suffix" {
  description = "Domain suffix for the API container"
  type        = string

  validation {
    condition     = var.api_container_domain_suffix != null
    error_message = "api_container_domain_suffix must be specified."
  }
}

variable "service_connect_dns_name" {
  description = "DNS name for Service Connect (e.g., backend)"
  type        = string

  validation {
    condition     = var.service_connect_dns_name != null
    error_message = "service_connect_dns_name must be specified."
  }
}

variable "ecr_repositories" {
  description = "ECR Repository names"
  type        = list(string)

  validation {
    condition     = length(var.ecr_repositories) >= 2
    error_message = "At least two ECR repositories must be specified."
  }
}

variable "ecr_repository_api" {
  description = "ECR Repository name for API service"
  type        = string

  validation {
    condition     = var.ecr_repository_api != null
    error_message = "ecr_repository_api must be specified."
  }
}

variable "ecr_repository_web" {
  description = "ECR Repository name for Web service"
  type        = string

  validation {
    condition     = var.ecr_repository_web != null
    error_message = "ecr_repository_web must be specified."
  }
}

variable "keycloak_client_url" {
  description = "Keycloak client URL"
  type        = string

  validation {
    condition     = var.keycloak_client_url != null
    error_message = "keycloak_client_url must be specified."
  }
}

variable "keycloak_api_client_id" {
  description = "Keycloak api client ID"
  type        = string

  validation {
    condition     = var.keycloak_api_client_id != null
    error_message = "keycloak_api_client_id must be specified."
  }
}

variable "keycloak_web_client_id" {
  description = "Keycloak web client ID"
  type        = string

  validation {
    condition     = var.keycloak_web_client_id != null
    error_message = "keycloak_web_client_id must be specified."
  }
}

variable "keycloak_realm" {
  description = "Keycloak realm name"
  type        = string

  validation {
    condition     = var.keycloak_realm != null
    error_message = "keycloak_realm must be specified."
  }
}
