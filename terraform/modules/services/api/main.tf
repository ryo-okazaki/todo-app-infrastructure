# ------------------------------------------------------------------------------
# Data Sources
# ------------------------------------------------------------------------------
data "aws_region" "current" {}

# ------------------------------------------------------------------------------
# CloudWatch Log Group
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.name}-logs"
  }
}

# ------------------------------------------------------------------------------
# IAM Role for Task Execution
# ------------------------------------------------------------------------------
resource "aws_iam_role" "execution_role" {
  name = "${var.name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.name}-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "execution_role_policy" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Secrets Manager アクセス権限を追加
resource "aws_iam_role_policy" "secrets_access" {
  count = length(var.secrets_arns) > 0 ? 1 : 0

  name = "${var.name}-secrets-access"
  role = aws_iam_role.execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Resource = var.secrets_arns
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# IAM Role for Task
# ------------------------------------------------------------------------------
resource "aws_iam_role" "task_role" {
  name = "${var.name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.name}-task-role"
  }
}

# ECS Exec用のポリシー
resource "aws_iam_role_policy" "task_exec_policy" {
  name = "${var.name}-task-exec-policy"
  role = aws_iam_role.task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# Task Definition
# ------------------------------------------------------------------------------
resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([{
    name  = "app"
    image = var.ecr_repository_url

    portMappings = [{
      name          = "api-port"
      containerPort = var.container_port
      protocol      = "tcp"
    }]

    environment = var.environment_variables != null ? [
      for key, value in var.environment_variables :
      {
        name  = key
        value = value
      }
    ] : []

    secrets = [
      {
        name      = "DATABASE_URL"
        valueFrom = var.database_url_secret_arn
      },
      {
        name      = "API_JWT_SECRET"
        valueFrom = var.api_jwt_secret_arn
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.this.name
        "awslogs-region"        = data.aws_region.current.id
        "awslogs-stream-prefix" = "ecs"
      }
    }

    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}${var.health_check_path} || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
  }])

  tags = {
    Name = "${var.name}-task"
  }
}

# ------------------------------------------------------------------------------
# Security Group
# ------------------------------------------------------------------------------
resource "aws_security_group" "this" {
  name        = "${var.name}-sg"
  description = "Security group for ${var.name} ECS service"
  vpc_id      = var.vpc_id

  # VPC内からの通信を許可 (Service Connect用)
  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow from VPC for Service Connect"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.name}-sg"
  }
}

# ------------------------------------------------------------------------------
# ECS Service
# ------------------------------------------------------------------------------
resource "aws_ecs_service" "this" {
  name            = "${var.name}-service"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.this.id]
    assign_public_ip = false
  }

  # Service Connect: Server mode
  service_connect_configuration {
    enabled   = true
    namespace = var.service_connect_namespace_arn

    service {
      discovery_name = var.service_connect_dns_name
      port_name      = "api-port"

      client_alias {
        port     = var.container_port
        dns_name = var.service_connect_dns_name
      }
    }
  }

  enable_execute_command = true
  force_new_deployment   = true

  # deployment_configuration {
  #   maximum_percent         = 200
  #   minimum_healthy_percent = 100
  # }

  tags = {
    Name        = "${var.name}-service"
    Environment = var.env
  }
}
