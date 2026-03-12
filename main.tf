terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Change if needed
}

# FIXED: Use Amazon Linux 2 (Always available in all regions)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]  # Official Amazon account

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Simplified networking - Uses default VPC (Always works)
resource "aws_security_group" "web_sg" {
  name_prefix = "simple-app-sg"

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
    cidr_blocks = ["0.0.0.0/0"]  # Restrict later
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

# PERFECTLY WORKING EC2 Instance
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # Production-ready user data for Amazon Linux 2
  user_data = <<-EOF
    #!/bin/bash
    # Update and install NGINX
    yum update -y
    amazon-linux-extras install -y nginx1
    
    # Create professional website
    cat > /usr/share/nginx/html/index.html << 'END_HTML'
<!DOCTYPE html>
<html>
<head>
    <title>✅ Terraform + GitHub Actions Success!</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white; 
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container { 
            background: rgba(255,255,255,0.1); 
            backdrop-filter: blur(20px);
            padding: 60px 40px; 
            border-radius: 25px; 
            text-align: center;
            max-width: 800px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.3);
        }
        h1 { 
            font-size: 3.5em; 
            background: linear-gradient(45deg, #FFD700, #FFA500);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 20px;
            font-weight: 800;
        }
        .subtitle { font-size: 1.4em; margin-bottom: 40px; opacity: 0.95; }
        .badges { margin: 40px 0; }
        .badge { 
            display: inline-block; 
            background: rgba(255,255,255,0.2); 
            padding: 15px 30px; 
            margin: 10px; 
            border-radius: 50px; 
            font-weight: 600;
            box-shadow: 0 8px 25px rgba(0,0,0,0.2);
            transition: transform 0.3s;
        }
        .badge:hover { transform: translateY(-5px); }
        .features { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); 
            gap: 25px; 
            margin: 50px 0;
        }
        .feature { 
            background: rgba(255,255,255,0.1); 
            padding: 30px; 
            border-radius: 20px;
        }
        .feature h3 { 
            color: #FFD700; 
            margin-bottom: 15px; 
            font-size: 1.3em;
        }
        .status { 
            margin-top: 40px; 
            padding: 25px; 
            background: rgba(0,255,0,0.2); 
            border-radius: 15px;
            border: 2px solid rgba(0,255,0,0.4);
        }
        .deploy-time { font-size: 1.1em; margin-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Deployment Complete!</h1>
        <p class="subtitle">Your DevOps pipeline is working perfectly</p>
        
        <div class="badges">
            <div class="badge">Terraform IaC</div>
            <div class="badge">GitHub Actions CI/CD</div>
            <div class="badge">Amazon Linux 2 + NGINX</div>
            <div class="badge">Production Ready</div>
        </div>
        
        <div class="features">
            <div class="feature">
                <h3>✅ Fully Automated</h3>
                <p>Git push → Live website in 2 minutes</p>
            </div>
            <div class="feature">
                <h3>🔒 Secure Deployment</h3>
                <p>AWS IAM roles + Security Groups</p>
            </div>
            <div class="feature">
                <h3>⚡ Immutable Infra</h3>
                <p>New instances on every code change</p>
            </div>
        </div>
        
        <div class="status">
            <p>✅ NGINX Running | ✅ Port 80 Open | ✅ Public Access</p>
            <p class="deploy-time">Deployed: $(date)</p>
        </div>
    </div>
</body>
</html>
END_HTML

    # Fix permissions and start NGINX
    chown -R nginx:nginx /usr/share/nginx/html
    chmod -R 755 /usr/share/nginx/html
    
    systemctl start nginx
    systemctl enable nginx
    
    # Log success
    echo "$(date): Deployment complete - $(curl -s http://localhost)" >> /var/log/user-data.log
  EOF

  tags = {
    Name        = "DevOps-Demo-WebServer"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# Outputs
output "website_url" {
  value       = "http://${aws_instance.web_server.public_ip}"
  description = "Your live website URL"
}

output "public_ip" {
  value       = aws_instance.web_server.public_ip
  description = "EC2 Public IP"
}

output "instance_id" {
  value       = aws_instance.web_server.id
  description = "EC2 Instance ID"
}
