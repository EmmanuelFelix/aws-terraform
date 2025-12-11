# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # Change to your desired region
}

# --- VPC, Subnet, and Internet Connectivity ---

# 1. Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "Public-EC2-VPC"
  }
}

# 2. Create a Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true # ESSENTIAL: Auto-assign public IP to instances
  availability_zone       = "us-east-1a" # Change AZ as needed
  tags = {
    Name = "Public-Subnet"
  }
}

# 3. Create an Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Public-EC2-IGW"
  }
}

# 4. Create a Route Table and define the public route (0.0.0.0/0)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "Public-Route-Table"
  }
}

# 5. Associate the Route Table with the Public Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# --- Security Group (Firewall) ---

# 6. Create a Security Group to allow public access
resource "aws_security_group" "allow_ssh_http" {
  vpc_id = aws_vpc.main.id
  name   = "allow_ssh_http"
  description = "Allow SSH and HTTP inbound traffic"

  # Ingress (Inbound) Rules
  ingress {
    description = "Allow SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP from anywhere (for testing web server)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress (Outbound) Rule (Allow all outbound traffic)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Public-Access-SG"
  }
}

# --- EC2 Instance ---

# 7. Find the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["al2023-ami-2023.*x86_64"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

# 8. Launch the EC2 Instance (FIXED)
resource "aws_instance" "public_ec2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id

  # CORRECT: Use the 'id' and the 'vpc_security_group_ids' parameter
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]

  # ADD THIS LINE: Attaches the key pair to the instance
  key_name = data.aws_key_pair.existing.key_name

  tags = {
    Name = "Public-Web-Server"
  }
}

# --- Output the Public IP Address ---

# 9. Output the public IP address for easy access
output "public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.public_ec2.public_ip
}


# DATA: Look up the existing key pair by its name
data "aws_key_pair" "existing" {
  key_name = var.existing_key_name
}

