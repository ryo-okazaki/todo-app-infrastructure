output "endpoint" {
  description = "Connection endpoint"
  value       = aws_db_instance.this.endpoint
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.this.db_name
}

output "username" {
  description = "Master username"
  value       = aws_db_instance.this.username
}

# パスワードはsensitiveなので出力しない、またはsensitive指定で出力する
