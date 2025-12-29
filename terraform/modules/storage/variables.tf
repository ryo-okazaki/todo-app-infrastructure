variable "env" {
  description = "Environment (e.g., development, staging, production)"
  type        = string
}

variable "name" {
  description = "リソース名のプレフィックス"
  type        = string
}

variable "force_destroy" {
  description = "Terraform destroy時にバケットの中身ごと削除するか (Devはtrue推奨)"
  type        = bool
  default     = false
}

variable "ecr_repositories" {
  description = "ECR Repository names"
  type        = list(string)
}
