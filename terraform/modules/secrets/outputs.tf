# ------------------------------------------------------------------------------
# CloudFront origin verification secret
# ------------------------------------------------------------------------------
output "cloudfront_origin_secret_value" {
  description = "CloudFront origin verification secret value"
  value       = random_password.cloudfront_origin.result
  sensitive   = true
}

output "cloudfront_origin_secret_arn" {
  description = "CloudFront origin verification secret ARN in Secrets Manager"
  value       = aws_secretsmanager_secret.cloudfront_origin.arn
}

output "cloudfront_origin_secret_name" {
  description = "CloudFront origin verification secret name in Secrets Manager"
  value       = aws_secretsmanager_secret.cloudfront_origin.name
}

# ------------------------------------------------------------------------------
# Database credentials secret
# ------------------------------------------------------------------------------
output "db_credentials_secret_arn" {
  description = "ARN of the database credentials secret (null if disabled)"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "database_url_secret_arn" {
  description = "ARN of the DATABASE_URL secret (null if disabled)"
  value       = aws_secretsmanager_secret.database_url.arn
}

# ------------------------------------------------------------------------------
# API JWT Secrets
# ------------------------------------------------------------------------------
output "api_jwt_secret_arn" {
  description = "API JWT secret ARN in Secrets Manager"
  value       = aws_secretsmanager_secret.api_jwt_secret.arn
}
