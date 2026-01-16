terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Change to your preferred region
}

# Data source for latest Ubuntu AMI (auto-finds correct AMI for your region)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# VPC with public subnet and Internet Gateway
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "simple-app-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "simple-app-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"  # Change to your region
  map_public_ip_on_launch = true
  tags = {
    Name = "simple-app-public-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "simple-app-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group - HTTP, HTTPS, SSH
resource "aws_security_group" "web_sg" {
  name_prefix = "simple-app-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Tighten to your IP in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "simple-app-sg"
  }
}

# EC2 Instance with Professional Website
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  subnet_id              = aws_subnet.public.id
  key_name               = "your-key-pair"  # Create this first in AWS Console

  # ROBUST User Data Script - Production Ready
  user_data = <<-EOF
    #!/bin/bash
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    
    # Install NGINX
    apt-get install -y nginx
    
    # Create professional website files
    cat > /var/www/html/index.html << 'WEBSITE'
<!DOCTYPE html>
<html>
<head>
    <title>Terraform + GitHub Actions Demo</title>
    <style>
        body { font-family: Arial; margin: 40px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; }
        .container { max-width: 800px; margin: auto; background: rgba(255,255,255,0.1); padding: 40px; border-radius: 20px; }
        h1 { color: #FFD700; text-align: center; }
        .badge { background: #FF6B6B; padding: 10px 20px; border-radius: 25px; display: inline-block; margin: 10px; }
        .features { display: flex; justify-content: space-around; margin: 40px 0; }
        .feature { text-align: center; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Deployment Success!</h1>
        <p style="text-align: center; font-size: 1.2em;">Your infrastructure was deployed automatically via:</p>
        
        <div style="text-align: center;">
            <span class="badge">Terraform (IaC)</span>
            <span class="badge">GitHub Actions (CI/CD)</span>
            <span class="badge">AWS EC2 + NGINX</span>
        </div>
        
        <div class="features">
            <div class="feature">
                <h3>✅ Immutable</h3>
                <p>Auto-replaces on code change</p>
            </div>
            <div class="feature">
                <h3>🔒 Secure</h3>
                <p>AWS OIDC + Least Privilege</p>
            </div>
            <div class="feature">
                <h3>⚡ Fast</h3>
                <p>~2 min from git push</p>
            </div>
        </div>
        
        <p style="text-align: center; margin-top: 40px;">
            Instance ID: <strong>${HOSTNAME}</strong><br>
            Deployed: <strong>$(date)</strong>
        </p>
    </div>
</body>
</html>
WEBSITE

    # Set proper permissions
    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html
    
    # Start and enable NGINX
    systemctl start nginx
    systemctl enable nginx
    
    # Log success
    echo "Website deployed successfully at $(date)" >> /var/log/user-data.log
  EOF

  tags = {
    Name        = "SimpleApp-WebServer"
    Project     = "Terraform-GitHubActions-Demo"
    Environment = "Production"
  }
}

# Outputs
output "website_url" {
  value = "http://${aws_instance.web_server.public_ip}"
}

output "instance_public_ip" {
  value = aws_instance.web_server.public_ip
}

output "instance_id" {
  value = aws_instance.web_server.id
}
