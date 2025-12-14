variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "domain name for development environment"
  type        = string
}

variable "parent_zone_id" {
  description = "hosted zone ID of the parent domain"
  type        = string
}

variable "dns_account_assume_role" {
  description = "ARN of the role to assume for cross-account access"
  type        = string
}
