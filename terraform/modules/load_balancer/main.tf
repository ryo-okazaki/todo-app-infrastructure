# ------------------------------------------------------------------------------
# Security Group for ALB
# ------------------------------------------------------------------------------
resource "aws_security_group" "this" {
  name        = "${var.name}-alb-sg"
  description = "Allow HTTP/HTTPS inbound"
  vpc_id      = var.vpc_id

  # HTTP (80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS (443)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress (All)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-alb-sg"
  }
}

# ------------------------------------------------------------------------------
# Application Load Balancer
# ------------------------------------------------------------------------------
resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  internal           = false # インターネット向け
  load_balancer_type = "application"
  security_groups    = [aws_security_group.this.id]
  subnets            = var.public_subnet_ids

  access_logs {
    bucket  = var.access_logs_bucket_id
    enabled = true
    prefix  = "alb-logs"
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

# ------------------------------------------------------------------------------
# Listener Rule: Validate CloudFront Custom Header
# ------------------------------------------------------------------------------
resource "aws_lb_listener_rule" "cloudfront_validated" {
  count = var.cloudfront_custom_header_name != null ? 1 : 0

  listener_arn = aws_lb_listener.https.arn
  priority     = 1

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Service Unavailable (No Target Group configured yet)"
      status_code  = "503"
    }
  }

  condition {
    http_header {
      http_header_name = var.cloudfront_custom_header_name
      values           = [var.cloudfront_custom_header_value]
    }
  }
}
