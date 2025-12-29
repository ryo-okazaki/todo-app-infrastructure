# ------------------------------------------------------------------------------
# ECR Repositories (Frontend & Backend)
# ------------------------------------------------------------------------------
locals {
  repos = ["frontend", "backend"]
}

resource "aws_ecr_repository" "this" {
  for_each             = toset(local.repos)
  name                 = "${var.name}-${each.key}"
  image_tag_mutability = "MUTABLE" # 同一タグの上書きを許可

  image_scanning_configuration {
    scan_on_push = true # Push時に脆弱性スキャン
  }

  tags = {
    Name = "${var.name}-${each.key}"
  }
}

# ライフサイクルポリシー (コスト削減: 最新30個だけ残す)
resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = toset(local.repos)
  repository = aws_ecr_repository.this[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 30 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# S3 Bucket (For Logs: ALB & CloudFront)
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "logs" {
  bucket        = "${var.name}-logs"
  force_destroy = var.force_destroy # 開発環境なら中身ごと消せるようにする

  tags = {
    Name = "${var.name}-logs"
  }
}

# ログバケットの暗号化
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ログバケットのパブリックアクセスブロック（完全閉鎖）
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ALBがログを書き込めるようにするためのバケットポリシー
data "aws_caller_identity" "current" {}
data "aws_elb_service_account" "main" {} # ALBのAWS公式アカウントIDを取得

resource "aws_s3_bucket_policy" "logs_alb" {
  depends_on = [
    aws_s3_bucket_public_access_block.logs,
    aws_s3_bucket_acl.logs
  ]

  bucket = aws_s3_bucket.logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowALBLogWrite"
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs.arn}/*"
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# S3 Bucket (For Assets: Static Files)
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "assets" {
  bucket        = "${var.name}-assets"
  force_destroy = var.force_destroy

  tags = {
    Name = "${var.name}-assets"
  }
}

# Assetsバケットの暗号化
resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Assetsバケットも直接公開はせず、後でCloudFront経由のみ許可する設定にします
# いったんパブリックアクセスはブロックしておきます
resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
