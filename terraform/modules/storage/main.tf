# ------------------------------------------------------------------------------
# Data Sources
# ------------------------------------------------------------------------------
data "aws_elb_service_account" "main" {}
data "aws_caller_identity" "current" {}

# ------------------------------------------------------------------------------
# ECR Repositories (Frontend & Backend)
# ------------------------------------------------------------------------------
resource "aws_ecr_repository" "this" {
  for_each             = toset(var.ecr_repositories)
  name                 = "${var.name}-${each.key}"
  image_tag_mutability = "MUTABLE" # 同一タグの上書きを許可
  force_delete         = var.force_destroy

  image_scanning_configuration {
    scan_on_push = true # Push時に脆弱性スキャン
  }

  tags = {
    Name = "${var.name}-${each.key}"
  }
}

# 初回のみ nginxイメージをECRにpushする
resource "null_resource" "push_initial_image" {
  for_each = aws_ecr_repository.this

  depends_on = [aws_ecr_repository.this]

  triggers = {
    ecr_repository_url = each.value.repository_url
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/push-ecr-nginx-image.sh"
    environment = {
      ECR_REPOSITORY_URL = each.value.repository_url
    }
  }

  lifecycle {
    ignore_changes = [triggers]
  }
}

# ライフサイクルポリシー (コスト削減: 最新30個だけ残す)
resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = toset(var.ecr_repositories)
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
  bucket        = "${var.env}-${data.aws_caller_identity.current.account_id}-${var.name}-logs"
  force_destroy = var.force_destroy # 開発環境なら中身ごと消せるようにする

  tags = {
    Name = "${var.name}-logs"
  }
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "logs" {
  depends_on = [aws_s3_bucket_ownership_controls.logs]

  bucket = aws_s3_bucket.logs.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = false
  block_public_policy     = true
  ignore_public_acls      = false
  restrict_public_buckets = true
}

# ライフサイクルポリシー（ログの自動削除）
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "delete_old_logs"
    status = "Enabled"

    expiration {
      days = 90 # 90日後に削除
    }

    # noncurrent_version_expiration {
    #   days = 30
    # }
  }
}

resource "aws_s3_bucket_policy" "logs_alb" {
  depends_on = [
    aws_s3_bucket_public_access_block.logs,
    aws_s3_bucket_acl.logs
  ]

  bucket = aws_s3_bucket.logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ALB がバケット情報を取得できるようにする
      {
        Sid    = "AllowALBGetBucketAcl"
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.logs.arn
      },
      # ALB がログを書き込めるようにする
      {
        Sid    = "AllowALBLogWrite"
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs.arn}/alb-logs/*"
      },
      # CloudFront用のログ書き込み権限（ACLベース）
      {
        Sid    = "AllowCloudFrontGetBucketAcl"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.logs.arn
      },
      {
        Sid    = "AllowCloudFrontPutObject"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs.arn}/cloudfront/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}
