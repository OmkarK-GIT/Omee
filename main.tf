provider "aws" {
  region = "us-east-1"
}

# 1. Store state in S3 (Optional but recommended for teams)
# terraform {
#   backend "s3" {
#     bucket = "my-terraform-state-bucket"
#     key    = "simple-app/terraform.tfstate"
#     region = "us-east-1"
#   }
# }

# 2. Security Group: Allow HTTP (80) and SSH (22)
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
    cidr_blocks = ["0.0.0.0/0"] # Restrict to your IP in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. EC2 Instance with Nginx Bootstrap
resource "aws_instance" "app_server" {
  ami           = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS (Update for your region!)
  instance_type = "t2.micro"
  security_groups = [aws_security_group.web_sg.name]

  # This script runs ONCE when the instance boots
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y nginx
              sudo systemctl start nginx
              sudo systemctl enable nginx
              
              # Deploy Simple Application
              echo "<h1>Deployed via Terraform & GitHub Actions!</h1>" | sudo tee /var/www/html/index.html
              EOF

  tags = {
    Name = "SimpleApp-Terraform"
  }
}

output "public_ip" {
  value = aws_instance.app_server.public_ip
}