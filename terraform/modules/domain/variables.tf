variable "domain_name" {
  description = "ドメイン名 (例: dev.example.com)"
  type        = string
}

variable "parent_zone_id" {
  description = "親ドメイン(ドメイン管理アカウント側)のHosted Zone ID"
  type        = string
}
