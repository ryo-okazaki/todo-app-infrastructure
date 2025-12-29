# ------------------------------------------------------------------------------
# Required Variables
# ------------------------------------------------------------------------------
variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "domain_name" {
  description = "Domain name for CloudFront (e.g., app.example.com)"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN (must be in us-east-1)"
  type        = string
}

variable "alb_domain_name" {
  description = "ALB DNS name for origin"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for DNS record"
  type        = string
}

# ------------------------------------------------------------------------------
# Optional Variables
# ------------------------------------------------------------------------------
variable "origin_custom_header_name" {
  description = "Custom header name for origin verification"
  type        = string
  default     = "X-CloudFront-Secret"
}

variable "origin_custom_header_value" {
  description = "Custom header value for origin verification (use secrets manager in production)"
  type        = string
  sensitive   = true
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_200" # Asia, Europe, North America
}

variable "default_ttl" {
  description = "Default TTL for cached objects (seconds)"
  type        = number
  default     = 0 # SSR: no caching by default
}

variable "max_ttl" {
  description = "Maximum TTL for cached objects (seconds)"
  type        = number
  default     = 31536000 # 1 year
}

variable "min_ttl" {
  description = "Minimum TTL for cached objects (seconds)"
  type        = number
  default     = 0
}

variable "enable_waf" {
  description = "Enable AWS WAF for CloudFront"
  type        = bool
  default     = false
}

variable "waf_web_acl_arn" {
  description = "WAF Web ACL ARN (required if enable_waf is true)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
