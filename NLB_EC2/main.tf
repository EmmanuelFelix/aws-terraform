terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# --- Variables ---
variable "key_name" {
  description = "The name of the existing AWS Key Pair you want to use"
  type        = string
  # You can set a default here or enter it when prompted by Terraform
  default = "aws_key_1" 
}

# --- Data Sources ---
# 1. Fetch the Existing Key Pair info
data "aws_key_pair" "existing" {
  key_name = var.key_name
  include_public_key = true
}

# 2. Fetch the latest Ubuntu 22.04 AMI (Dynamic for any region)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- Networking ---
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "nlb-demo-vpc" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# --- Security Group ---
resource "aws_security_group" "ssh_allow" {
  name        = "allow_ssh_nlb"
  description = "Allow SSH traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # Note: NLBs preserve client IP. Use 0.0.0.0/0 or your specific Client IP.
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- EC2 Instance ---
resource "aws_instance" "server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  
  # Uses the variable provided at runtime
  key_name      = data.aws_key_pair.existing.key_name
  
  vpc_security_group_ids = [aws_security_group.ssh_allow.id]

  tags = { Name = "Terraform-EC2-NLB-Target" }
}

# --- Network Load Balancer (NLB) ---
resource "aws_lb" "nlb" {
  name               = "ssh-nlb-demo"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public.id]
}

resource "aws_lb_target_group" "ssh_tg" {
  name     = "ssh-tg-demo"
  port     = 22
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id
  
  health_check {
    protocol = "TCP"
    port     = "traffic-port"
  }
}

resource "aws_lb_listener" "ssh_listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "22"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ssh_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "main" {
  target_group_arn = aws_lb_target_group.ssh_tg.arn
  target_id        = aws_instance.server.id
  port             = 22
}

# --- Outputs ---
output "ssh_command" {
  description = "Command to connect to the EC2 via the NLB"
  value       = "ssh -i /path/to/${var.key_name}.pem ubuntu@${aws_lb.nlb.dns_name}"
}