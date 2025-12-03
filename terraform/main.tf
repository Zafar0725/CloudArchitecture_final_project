########################################
# LOCALS
########################################

locals {
  project_prefix = var.project_prefix
}

########################################
# S3 BUCKETS (4 PRIVATE + VERSIONING)
########################################

# 1) Create S3 buckets (using for_each loop)
resource "aws_s3_bucket" "private_buckets" {
  for_each = toset(var.s3_bucket_names)

  bucket = each.value

  tags = {
    Project = local.project_prefix
    Owner   = "Zafar"
  }
}

# 2) Block all public access on each bucket
resource "aws_s3_bucket_public_access_block" "private_buckets" {
  for_each = aws_s3_bucket.private_buckets

  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 3) Enable versioning on each bucket (bonus requirement)
resource "aws_s3_bucket_versioning" "private_buckets" {
  for_each = aws_s3_bucket.private_buckets

  bucket = each.value.id

  versioning_configuration {
    status = "Enabled"
  }
}

########################################
# VPC + PUBLIC SUBNET + INTERNET ACCESS
########################################

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "${local.project_prefix}-vpc"
    Project = local.project_prefix
  }
}

# Public subnet (forced to us-east-1a so t3.micro is supported)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name    = "${local.project_prefix}-public-subnet"
    Project = local.project_prefix
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${local.project_prefix}-igw"
    Project = local.project_prefix
  }
}

# Route table for public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${local.project_prefix}-public-rt"
    Project = local.project_prefix
  }
}

# Route to internet
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Associate route table with public subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

########################################
# SECURITY GROUP + EC2 INSTANCE
########################################

# Security group for EC2 (SSH from YOUR IP only)
resource "aws_security_group" "ec2_sg" {
  name        = "${local.project_prefix}-ec2-sg"
  description = "Allow SSH from my IP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${local.project_prefix}-ec2-sg"
    Project = local.project_prefix
  }
}

# EC2 instance
resource "aws_instance" "app" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

  tags = {
    Name    = "${local.project_prefix}-ec2"
    Project = local.project_prefix
    Owner   = "Zafar"
  }
}

########################################
# RDS SUBNETS + SUBNET GROUP
########################################

# Two subnets for RDS (in different AZs)
resource "aws_subnet" "db_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"

  tags = {
    Name    = "${local.project_prefix}-db-subnet-a"
    Project = local.project_prefix
  }
}

resource "aws_subnet" "db_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1b"

  tags = {
    Name    = "${local.project_prefix}-db-subnet-b"
    Project = local.project_prefix
  }
}

resource "aws_db_subnet_group" "db" {
  name       = "zafar-9027671-db-subnet-group"
  subnet_ids = [aws_subnet.db_a.id, aws_subnet.db_b.id]

  tags = {
    Name    = "zafar-9027671-db-subnet-group"
    Project = local.project_prefix
  }
}


########################################
# RDS SECURITY GROUP
########################################

resource "aws_security_group" "rds_sg" {
  name        = "${local.project_prefix}-rds-sg"
  description = "Allow MySQL from my IP"
  vpc_id      = aws_vpc.main.id

  # MySQL from YOUR IP (laptop)
  ingress {
    description = "MySQL from my IP"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${local.project_prefix}-rds-sg"
    Project = local.project_prefix
  }
}

########################################
# RDS MYSQL INSTANCE (PUBLIC)
########################################

resource "aws_db_instance" "mysql" {
  identifier              = "zafar-9027671-mysql"
  allocated_storage       = 20
  engine                  = "mysql"
  engine_version          = "8.0" # ok to leave like this
  instance_class          = "db.t3.micro"
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.db.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  publicly_accessible     = true # as you chose
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 0

  tags = {
    Name    = "${local.project_prefix}-mysql"
    Project = local.project_prefix
  }
}
