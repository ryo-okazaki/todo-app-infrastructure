variable "domain_name" {
  description = "Domain name for SES (e.g., ryo-okazaki.com)"
  type        = string
}

variable "zone_id" {
  description = "Route53 Hosted Zone ID for domain verification"
  type        = string
}

variable "from_email_addresses" {
  description = "List of email addresses to verify (e.g., ['noreply@ryo-okazaki.com', 'support@ryo-okazaki.com'])"
  type        = list(string)
  default     = []
}

variable "enable_dkim" {
  description = "Enable DKIM signing"
  type        = bool
  default     = true
}

variable "enable_configuration_set" {
  description = "Enable SES Configuration Set for tracking"
  type        = bool
  default     = true
}

variable "configuration_set_name" {
  description = "Name of the SES Configuration Set"
  type        = string
  default     = null
}

variable "enable_sns_notifications" {
  description = "Enable SNS notifications for bounce/complaint"
  type        = bool
  default     = false
}

variable "sns_topic_name" {
  description = "SNS topic name for SES notifications"
  type        = string
  default     = null
}

variable "daily_sending_quota" {
  description = "Maximum number of emails per day (only for sandbox exit)"
  type        = number
  default     = null
}

variable "max_send_rate" {
  description = "Maximum send rate per second (only for sandbox exit)"
  type        = number
  default     = null
}
