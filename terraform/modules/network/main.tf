# --- VPC ---
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.name}-vpc"
  }
}

# --- Internet Gateway ---
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name}-igw"
  }
}

# --- Public Subnets ---
resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.name}-public-${var.azs[count.index]}"
    Type = "Public"
  }
}

# --- Private Subnets ---
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.name}-private-${var.azs[count.index]}"
    Type = "Private"
  }
}

# --- Database Subnets ---
resource "aws_subnet" "database" {
  count             = length(var.database_private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.database_private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.name}-database-${var.azs[count.index]}"
    Type = "Database"
  }
}

# --- Public Route Table ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.name}-public-rt"
  }
}

# Route Table Association (Public)
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- NAT Gateway (Multi-AZ) ---
# EIP for NAT
resource "aws_eip" "nat" {
  count  = length(var.public_subnet_cidrs)
  domain = "vpc"

  tags = {
    Name = "${var.name}-nat-eip-${var.azs[count.index]}"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "this" {
  count         = length(var.public_subnet_cidrs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id # Publicに配置

  tags = {
    Name = "${var.name}-nat-${var.azs[count.index]}"
  }

  depends_on = [aws_internet_gateway.this]
}

# --- Private Route Tables (AZごとに作成) ---
# NAT Gatewayが各AZにあるため、ルートテーブルも分ける必要があります
resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index].id
  }

  tags = {
    Name = "${var.name}-private-rt-${var.azs[count.index]}"
  }
}

# Route Table Association (Private)
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# --- Database Route Tables ---
# VPC内部の通信のみ許可
resource "aws_route_table" "database" {
  count  = length(var.database_private_subnet_cidrs)
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name}-database-rt-${var.azs[count.index]}"
  }
}

# Route Table Association (Database)
resource "aws_route_table_association" "database" {
  count          = length(var.database_private_subnet_cidrs)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[count.index].id
}

# ------------------------------------------------------------------------------
# Service Discovery Namespace (for ECS Service Connect)
# ------------------------------------------------------------------------------
resource "aws_service_discovery_private_dns_namespace" "this" {
  name        = var.api_container_domain_suffix # コンテナ間通信のdomain suffix
  description = "Service Connect namespace for ${var.name}"
  vpc         = aws_vpc.this.id
}
