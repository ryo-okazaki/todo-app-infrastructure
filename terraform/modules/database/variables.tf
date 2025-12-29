variable "name" {
  description = "リソース名のプレフィックス"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

# ToDo: バックエンドのコンテナからのアクセスのみ許可するようにSGの範囲を変更する
variable "vpc_cidr" {
  description = "VPCのCIDR (セキュリティグループの許可範囲に使用)"
  type        = string
}

variable "private_subnet_ids" {
  description = "DBを配置するプライベートサブネットのIDリスト"
  type        = list(string)
}

variable "db_name" {
  description = "データベース名"
  type        = string
  default     = "app_db"
}

variable "db_username" {
  description = "マスターユーザー名"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "マスターパスワード (sensitive)"
  type        = string
  sensitive   = true
}

variable "db_port" {
  description = "データベースのポート番号"
  type        = number
  default     = 5432
}

variable "instance_class" {
  description = "インスタンスクラス (例: db.t3.micro)"
  type        = string
}

variable "multi_az" {
  description = "Multi-AZを有効にするか (Prodはtrue, Devはfalse)"
  type        = bool
  default     = false
}
