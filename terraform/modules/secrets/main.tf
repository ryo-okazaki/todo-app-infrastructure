# ------------------------------------------------------------------------------
# CloudFront Origin Verification Secret
# ------------------------------------------------------------------------------
resource "random_password" "cloudfront_origin" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "cloudfront_origin" {
  name                    = "${var.name}-cloudfront-origin-secret"
  description             = "Secret for CloudFront to ALB origin verification"
  recovery_window_in_days = var.recovery_window_in_days

  tags = {
    Name = "${var.name}-cloudfront-origin-secret"
  }
}

resource "aws_secretsmanager_secret_version" "cloudfront_origin" {
  secret_id     = aws_secretsmanager_secret.cloudfront_origin.id
  secret_string = random_password.cloudfront_origin.result
}

# ------------------------------------------------------------------------------
# DB Secrets
# ------------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.name}-db-credentials"
  description             = "Database credentials for ${var.name}"
  recovery_window_in_days = var.recovery_window_in_days

  tags = {
    Name = "${var.name}-db-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    dbname   = var.db_name
    host     = var.db_host
    port     = var.db_port
    engine   = "postgres"
  })
}

resource "aws_secretsmanager_secret" "database_url" {
  name                    = "${var.name}-database-url"
  description             = "DATABASE_URL for ${var.name}"
  recovery_window_in_days = var.recovery_window_in_days

  tags = {
    Name = "${var.name}-database-url"
  }
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id = aws_secretsmanager_secret.database_url.id

  secret_string = "postgresql://${var.db_username}:${var.db_password}@${var.db_host}:${var.db_port}/${var.db_name}?schema=public"
}

# ------------------------------------------------------------------------------
# API JWT Secrets
# ------------------------------------------------------------------------------
resource "random_password" "api_jwt_secret" {
  length  = 64
  special = false
}

resource "aws_secretsmanager_secret" "api_jwt_secret" {
  name                    = "${var.name}-api-jwt-secret"
  description             = "API JWT Secret for ${var.name}"
  recovery_window_in_days = var.recovery_window_in_days

  tags = {
    Name = "${var.name}-api-jwt-secret"
  }
}

resource "aws_secretsmanager_secret_version" "api_jwt_secret" {
  secret_id     = aws_secretsmanager_secret.api_jwt_secret.id
  secret_string = random_password.api_jwt_secret.result
}
