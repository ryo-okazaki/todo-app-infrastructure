# ------------------------------------------------------------------------------
# Required Variables
# ------------------------------------------------------------------------------
variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ALB will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener"
  type        = string
}

# ------------------------------------------------------------------------------
# Optional Variables
# ------------------------------------------------------------------------------
variable "access_logs_bucket_id" {
  description = "S3 bucket ID for ALB access logs (optional)"
  type        = string
  default     = null
}

variable "allow_http_from_cloudfront" {
  description = "Allow HTTP (80) from CloudFront (for redirect purposes)"
  type        = bool
  default     = false
}

# ------------------------------------------------------------------------------
# CloudFront Integration Variables
# ------------------------------------------------------------------------------
variable "cloudfront_custom_header_name" {
  description = "Custom header name from CloudFront for origin verification"
  type        = string
  default     = null
}

variable "cloudfront_custom_header_value" {
  description = "Custom header value from CloudFront for origin verification"
  type        = string
  sensitive   = true
  default     = null
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
