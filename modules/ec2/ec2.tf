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

variable "sg_id" {}