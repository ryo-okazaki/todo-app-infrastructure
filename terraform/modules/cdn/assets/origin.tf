# ------------------------------------------------------------------------------
# Data Sources
# ------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

# ------------------------------------------------------------------------------
# S3 Bucket: Static Assets (Next.js builds)
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "static_assets" {
  bucket        = "${var.environment}-${data.aws_caller_identity.current.account_id}-static-assets"
  force_destroy = var.force_destroy

  tags = {
    Name        = "static-assets"
    Environment = var.environment
    Purpose     = "Next.js static assets _next/static"
  }
}

resource "aws_s3_bucket_versioning" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  versioning_configuration {
    status = "Disabled" # 静的アセットはimmutableなのでバージョニング不要
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true # コスト削減
  }
}

resource "aws_s3_bucket_public_access_block" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ライフサイクルポリシー（古いファイルの自動削除）
resource "aws_s3_bucket_lifecycle_configuration" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  rule {
    id     = "delete_old_static_files"
    status = "Enabled"

    # 90日以上前のファイルを削除（キャッシュバスティングで更新されるため）
    expiration {
      days = 90
    }

    # noncurrent_version_expiration {
    #   days = 1
    # }
  }
}

# CORS設定（開発時のlocalhost含む）
resource "aws_s3_bucket_cors_configuration" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"] # 静的アセットは完全パブリック
    max_age_seconds = 3600
  }
}

# ------------------------------------------------------------------------------
# S3 Bucket: media (User-uploaded content)
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "media" {
  bucket        = "${var.environment}-${data.aws_caller_identity.current.account_id}-media"
  force_destroy = var.force_destroy

  tags = {
    Name        = "media"
    Environment = var.environment
    Purpose     = "User-uploaded media contents"
  }
}

resource "aws_s3_bucket_versioning" "media" {
  bucket = aws_s3_bucket.media.id

  versioning_configuration {
    status = "Enabled" # 誤削除対策
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "media" {
  bucket = aws_s3_bucket.media.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ライフサイクルポリシー（削除済みユーザーの画像管理）
resource "aws_s3_bucket_lifecycle_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  rule {
    id     = "archive_deleted_users"
    status = "Enabled"

    # 削除マーク付きファイルを30日後にGlacierへ
    transition {
      days          = 30
      storage_class = "GLACIER_IR" # Glacier Instant Retrieval
    }

    # 削除マーク付きファイルを180日後に完全削除
    # noncurrent_version_expiration {
    #   days = 180
    # }
  }

  rule {
    id     = "abort_incomplete_multipart_uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# CORS設定（特定ドメインのみ許可）
resource "aws_s3_bucket_cors_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  cors_rule {
    allowed_headers = ["Content-Type", "Content-Length", "Content-MD5"]
    allowed_methods = ["GET", "HEAD", "PUT", "POST"]
    allowed_origins = [
      "https://${local.static_assets_domain}",
      "https://${local.media_domain}",
      "http://localhost:3000", # 開発環境用
    ]
    expose_headers  = ["ETag"]
    max_age_seconds = 300
  }
}

# ------------------------------------------------------------------------------
# CloudFront Origin Access Identity (OAI)
# ------------------------------------------------------------------------------
resource "aws_cloudfront_origin_access_identity" "static_assets" {
  comment = "OAI for static assets"
}

resource "aws_cloudfront_origin_access_identity" "media" {
  comment = "OAI for media"
}

# ------------------------------------------------------------------------------
# S3 Bucket Policies (CloudFront OAI経由のみ許可)
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "static_assets" {
  statement {
    sid    = "AllowCloudFrontOAI"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.static_assets.iam_arn]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.static_assets.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id
  policy = data.aws_iam_policy_document.static_assets.json
}

data "aws_iam_policy_document" "media" {
  statement {
    sid    = "AllowCloudFrontOAI"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.media.iam_arn]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.media.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "media" {
  bucket = aws_s3_bucket.media.id
  policy = data.aws_iam_policy_document.media.json
}
