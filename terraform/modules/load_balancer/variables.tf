variable "name" {
  description = "リソース名のプレフィックス"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "ALBを配置するパブリックサブネットのIDリスト"
  type        = list(string)
}

variable "acm_certificate_arn" {
  description = "HTTPSリスナーに使用するACM証明書のARN"
  type        = string
}

variable "access_logs_bucket_id" {
  description = "アクセスログ保存先のS3バケットID"
  type        = string
}
