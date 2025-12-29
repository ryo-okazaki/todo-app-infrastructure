# ------------------------------------------------------------------------------
# Required Variables
# ------------------------------------------------------------------------------
variable "name" {
  description = "Name prefix for secrets"
  type        = string
}

# ------------------------------------------------------------------------------
# Optional Variables
# ------------------------------------------------------------------------------
variable "recovery_window_in_days" {
  description = "Number of days before the secret is permanently deleted (0 for immediate deletion in development)"
  type        = number
  default     = 7
}

# ------------------------------------------------------------------------------
# DB Variables
# ------------------------------------------------------------------------------
variable "db_name" {
  description = "Database name"
  type        = string
  sensitive   = true
  nullable    = true
  default     = null
}

variable "db_username" {
  description = "Master username"
  type        = string
  sensitive   = true
  nullable    = true
  default     = null
}

variable "db_password" {
  description = "Master password"
  type        = string
  sensitive   = true
  nullable    = true
  default     = null
}

variable "db_host" {
  description = "Database host (RDS endpoint address)"
  type        = string
  nullable    = true
  default     = null
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = null
}
