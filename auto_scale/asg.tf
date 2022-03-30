terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region     = "ap-south-1"
}

variable instance_type {
  type        = string
  description = "t2.micro/t2.medium"
}

variable port_ip {
  description = "Enter CIDR range for launching instances, Eg: 10.0.0.0/16"
}

# Create a VPC
resource "aws_vpc" "vpc1" {
  cidr_block = var.port_ip
}

data "aws_availability_zones" "all" {}

variable "server_port" {
  description = "The port the web server will be listening"
  type        = number
  default     = 8080
}

variable "elb_port" {
  description = "The port the elb will be listening"
  type        = number
  default     = 80
}

resource "aws_launch_configuration" "asg-launch-config" {
  image_id          = "ami-0851b76e8b1bce90b"
  instance_type = var.instance_type
  security_groups = [aws_security_group.busybox.id]
  
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, Terraform & AWS ASG" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "busybox" {
  name = "terraform-busybox-sg"
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "elb-sg" {
  name = "terraform-sample-elb-sg"
  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Inbound HTTP from anywhere
  ingress {
    from_port   = var.elb_port
    to_port     = var.elb_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_autoscaling_group" "asg" {
  launch_configuration = aws_launch_configuration.asg-launch-config.id
  availability_zones   = data.aws_availability_zones.all.names
  min_size = 2
  max_size = 5

  load_balancers    = [aws_elb.elb.name]
  health_check_type = "ELB"

  tag {
    key                 = "Name"
    value               = "terraform-asg"
    propagate_at_launch = true
  }
}

resource "aws_elb" "elb" {
  name               = "terraform-asg"
  security_groups    = [aws_security_group.elb-sg.id]
  availability_zones = data.aws_availability_zones.all.names

  health_check {
    target              = "HTTP:${var.server_port}/"
    interval            = 30
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  # Adding a listener for incoming HTTP requests.
  listener {
    lb_port           = var.elb_port
    lb_protocol       = "http"
    instance_port     = var.server_port
    instance_protocol = "http"
  }
}

output "elb_dns_name" {
  value       = aws_elb.elb.dns_name
  description = "The domain name of the load balancer"
}


