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
# Listener: HTTPS (443)
# ------------------------------------------------------------------------------
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08" # 一般的な互換性重視ポリシー
  certificate_arn   = var.acm_certificate_arn

  # デフォルトアクション: まだアプリがないので「固定レスポンス」を返す
  # (後でECSサービス作成時に、パスベースルーティングなどで上書き・優先されます)
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Service Unavailable (No Target Group configured yet)"
      status_code  = "503"
    }
  }
}
