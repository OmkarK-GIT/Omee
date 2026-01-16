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

# Data source for latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "simple-app-vpc" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "simple-app-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = { Name = "simple-app-public-subnet" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "simple-app-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "web_sg" {
  name_prefix = "simple-app-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# FIXED EC2 Instance - No Terraform Variables in HTML
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  subnet_id              = aws_subnet.public.id
  # Remove key_name if you don't have one yet

  user_data = <<-EOF
    #!/bin/bash
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y nginx
    
    # Professional Website - STATIC CONTENT (No Terraform vars)
    cat > /var/www/html/index.html << 'END_HTML'
<!DOCTYPE html>
<html>
<head>
    <title>Terraform + GitHub Actions Demo</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 0; 
            padding: 40px; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
            color: white; 
            min-height: 100vh;
        }
        .container { 
            max-width: 900px; 
            margin: auto; 
            background: rgba(255,255,255,0.1); 
            padding: 50px; 
            border-radius: 20px; 
            backdrop-filter: blur(10px);
        }
        h1 { 
            color: #FFD700; 
            text-align: center; 
            font-size: 3em; 
            margin-bottom: 10px;
        }
        .subtitle { 
            text-align: center; 
            font-size: 1.4em; 
            margin-bottom: 40px; 
            opacity: 0.9;
        }
        .badges { 
            text-align: center; 
            margin-bottom: 50px;
        }
        .badge { 
            background: #FF6B6B; 
            padding: 12px 24px; 
            border-radius: 30px; 
            display: inline-block; 
            margin: 8px; 
            font-weight: bold;
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
        }
        .features { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); 
            gap: 30px; 
            margin: 50px 0;
        }
        .feature { 
            text-align: center; 
            padding: 30px; 
            background: rgba(255,255,255,0.1); 
            border-radius: 15px;
        }
        .feature h3 { 
            color: #FFD700; 
            margin-bottom: 15px;
        }
        .status { 
            text-align: center; 
            margin-top: 50px; 
            padding: 20px; 
            background: rgba(0,0,0,0.2); 
            border-radius: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Deployment Success!</h1>
        <p class="subtitle">Infrastructure deployed automatically via GitOps</p>
        
        <div class="badges">
            <span class="badge">Terraform IaC</span>
            <span class="badge">GitHub Actions</span>
            <span class="badge">AWS EC2 + NGINX</span>
            <span class="badge">Zero Downtime</span>
        </div>
        
        <div class="features">
            <div class="feature">
                <h3>✅ Immutable Infrastructure</h3>
                <p>Instances auto-replace on code changes</p>
            </div>
            <div class="feature">
                <h3>🔒 Secure by Design</h3>
                <p>AWS OIDC authentication, least privilege</p>
            </div>
            <div class="feature">
                <h3>⚡ 2-Minute Deployments</h3>
                <p>Push to main → Live website instantly</p>
            </div>
        </div>
        
        <div class="status">
            <p>✅ NGINX Active | ✅ Port 80 Open | ✅ Public IP Accessible</p>
            <p>Deployed: $(date)</p>
        </div>
    </div>
</body>
</html>
END_HTML

    # Fix permissions
    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html
    
    # Start NGINX
    systemctl start nginx
    systemctl enable nginx
    
    # Log success
    echo "$(date): Website deployed successfully" >> /var/log/user-data.log
  EOF

  tags = {
    Name = "DevOps-Demo-WebServer"
  }
}

output "website_url" {
  value = "http://${aws_instance.web_server.public_ip}"
}

output "public_ip" {
  value = aws_instance.web_server.public_ip
}
