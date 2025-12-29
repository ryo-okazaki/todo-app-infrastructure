# ------------------------------------------------------------------------------
# CloudFront Managed Prefix List
# ------------------------------------------------------------------------------
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# ------------------------------------------------------------------------------
# Security Group for ALB (CloudFront Only)
# ------------------------------------------------------------------------------
resource "aws_security_group" "this" {
  name        = "${var.name}-alb-sg"
  description = "Allow HTTPS inbound from CloudFront only"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name}-alb-sg"
  }
}

# HTTP (80) - CloudFront からのリダイレクト用
# CloudFrontはHTTPSで接続するため、本来不要だが互換性のため残す場合
resource "aws_security_group_rule" "http_from_cloudfront" {
  count = var.allow_http_from_cloudfront ? 1 : 0

  security_group_id = aws_security_group.this.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  description       = "HTTP from CloudFront (redirect only)"
}

# HTTPS (443) - CloudFront からのみ許可
resource "aws_security_group_rule" "https_from_cloudfront" {
  security_group_id = aws_security_group.this.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  description       = "HTTPS from CloudFront only"
}

# Egress (All)
resource "aws_security_group_rule" "egress_all" {
  security_group_id = aws_security_group.this.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
}

# ------------------------------------------------------------------------------
# Application Load Balancer
# ------------------------------------------------------------------------------
resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  internal           = false # インターネット向け（CloudFront経由）
  load_balancer_type = "application"
  security_groups    = [aws_security_group.this.id]
  subnets            = var.public_subnet_ids

  # CloudFrontからの接続のためdrop_invalid_header_fieldsを有効化
  drop_invalid_header_fields = true

  dynamic "access_logs" {
    for_each = var.access_logs_bucket_id != null ? [1] : []
    content {
      bucket  = var.access_logs_bucket_id
      enabled = true
      prefix  = "alb-logs"
    }
  }

  tags = {
    Name = "${var.name}-alb"
  }
}

# ------------------------------------------------------------------------------
# Listener: HTTP (80) -> Redirect to HTTPS
# ------------------------------------------------------------------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ------------------------------------------------------------------------------
# Listener: HTTPS (443) with CloudFront Header Validation
# ------------------------------------------------------------------------------
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06" # TLS 1.3対応の最新ポリシー
  certificate_arn   = var.acm_certificate_arn

  # デフォルトアクション: CloudFrontヘッダーがない場合は403
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden - Direct access not allowed"
      status_code  = "403"
    }
  }
}
