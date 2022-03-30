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

variable instance_count {
  type        = number
}

variable instance_type {
  type        = string
  description = "t2.micro/t2.medium"  
}

variable port_ip {
  description = "Enter CIDR range for launching instances eg: '10.0.0.0/16'"
}

# Create a VPC
resource "aws_vpc" "vpc1" {
  cidr_block = var.port_ip
}

resource "aws_instance" "ec2" {
  count = var.instance_count
  ami = "ami-0851b76e8b1bce90b"
  instance_type = var.instance_type
  vpc_security_group_ids = var.sg_id
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow Ssh inbound traffic"


  ingress {
    description      = "ssh connection"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

module "log_group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "~> 2.0"

  name              = "cloud_watch"
  retention_in_days = 120
}
