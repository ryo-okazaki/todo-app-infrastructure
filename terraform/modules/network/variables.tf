variable "name" {
  description = "リソース名のプレフィックス (例: todo-app-dev)"
  type        = string
}

variable "vpc_cidr" {
  description = "VPCのCIDRブロック"
  type        = string
}

variable "azs" {
  description = "使用するAvailability Zonesのリスト"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "public subnetのCIDRリスト"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "private subnetのCIDRリスト"
  type        = list(string)
}

variable "database_private_subnet_cidrs" {
  description = "database subnetのCIDRリスト"
  type        = list(string)
}

variable "api_container_domain_suffix" {
  description = "APIコンテナのdomain suffix"
  type        = string
}
