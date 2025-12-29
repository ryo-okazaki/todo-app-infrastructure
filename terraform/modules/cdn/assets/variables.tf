variable "environment" {
  description = "Environment name"
  type        = string
}

variable "force_destroy" {
  description = "Allow destroying S3 buckets with contents"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Base domain name (e.g., dev.todo-app.ryo-okazaki.com)"
  type        = string
}

variable "static_assets_subdomain" {
  description = "Subdomain for static assets (e.g., 'cdn' -> cdn.dev.todo-app.ryo-okazaki.com)"
  type        = string
  default     = "cdn"
}

variable "media_subdomain" {
  description = "Subdomain for media (e.g., 'media' -> media.dev.todo-app.ryo-okazaki.com)"
  type        = string
  default     = "media"
}

variable "cloudfront_certificate_arn" {
  description = "ACM certificate ARN for CloudFront (must be from domain module)"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID (from domain module)"
  type        = string
}

variable "logs_bucket_id" {
  description = "S3 bucket ID for CloudFront logs (from storage module)"
  type        = string
}

variable "enable_waf" {
  description = "Enable AWS WAF for CloudFront"
  type        = bool
  default     = false
}

variable "waf_web_acl_id" {
  description = "WAF Web ACL ID (required if enable_waf is true)"
  type        = string
  default     = null
}
