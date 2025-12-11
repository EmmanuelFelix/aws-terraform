terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # Change this to your preferred region
}

# ---------------------------------------------------------
# 1. Networking (VPC, Subnets, Security Group)
# ---------------------------------------------------------

# Create a Virtual Private Cloud (VPC)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "rds-terraform-vpc" }
}

# Create a Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = { Name = "rds-public-subnet" }
}

# Create a Second Public Subnet (RDS requires at least 2 AZs)
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"

  tags = { Name = "rds-public-subnet-2" }
}

# Internet Gateway for internet access
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# Route Table for Public Access
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# Associate Route Table with Subnets
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

# DB Subnet Group (Groups the subnets for RDS)
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.public.id, aws_subnet.public_2.id]

  tags = { Name = "My DB subnet group" }
}

# Security Group: Allow access ONLY from your IP
data "http" "myip" {
  url = "https://checkip.amazonaws.com"
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Allow DB access from my IP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "PostgreSQL from my IP"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------------------------------------
# 2. RDS Instance
# ---------------------------------------------------------

resource "aws_db_instance" "default" {
  allocated_storage      = 20
  db_name                = "mydb"
  identifier             = "my-terraform-rds"
  engine                 = "postgres"
  engine_version         = "16.3"      # Use a supported version
  instance_class         = "db.t3.micro"
  username               = "dbadmin"
  password               = "SuperSecretPass123!" # Ideally, use var or secrets manager
  parameter_group_name   = "default.postgres16"
  skip_final_snapshot    = true
  publicly_accessible    = true        # Set to true only for testing/dev
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name

  tags = { Name = "My RDS Instance" }
}

# ---------------------------------------------------------
# 3. Outputs
# ---------------------------------------------------------

output "rds_hostname" {
  description = "RDS instance hostname"
  value       = aws_db_instance.default.address
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.default.port
}

output "rds_username" {
  description = "RDS instance root username"
  value       = aws_db_instance.default.username
}

output "connect_command" {
  value = "psql -h ${aws_db_instance.default.address} -p ${aws_db_instance.default.port} -U ${aws_db_instance.default.username} -d mydb"
}