# --- Subnet Group ---
resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnet-group"
  subnet_ids = var.database_subnet_ids

  tags = {
    Name = "${var.name}-db-subnet-group"
  }
}

# --- Security Group ---
resource "aws_security_group" "this" {
  name        = "${var.name}-db-sg"
  description = "Security group for RDS"
  vpc_id      = var.vpc_id

  # Ingress: VPC内部からのPostgreSQL接続を許可
  ingress {
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Egress: アウトバウンドは全許可 (デフォルト)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-db-sg"
  }
}

# --- Parameter Group ---
resource "aws_db_parameter_group" "this" {
  name   = "${var.name}-pg"
  family = "postgres18" # エンジンバージョンに合わせる

  tags = {
    Name = "${var.name}-pg"
  }
}

# --- RDS Instance ---
resource "aws_db_instance" "this" {
  identifier = "${var.name}-rds"

  # Engine
  engine         = "postgres"
  engine_version = "18"
  instance_class = var.instance_class

  # Storage
  allocated_storage     = 20
  max_allocated_storage = 100 # 自動拡張
  storage_type          = "gp3"
  storage_encrypted     = true

  # Network
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  multi_az               = var.multi_az
  publicly_accessible    = false

  # Auth
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Settings
  parameter_group_name = aws_db_parameter_group.this.name
  skip_final_snapshot  = true # 開発用なので削除時スナップショットをスキップ

  tags = {
    Name = "${var.name}-rds"
  }
}
