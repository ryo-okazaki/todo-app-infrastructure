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
}
