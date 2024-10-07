provider "aws" {
  region = "${var.aws_region}"
}

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}
locals {
  tags = {
    Environment = "${var.environment}"
    Project = "${var.project}"
    CreatedOn = formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())
  }
  myIp = "${chomp(data.http.myip.response_body)}"
}
terraform {
  required_version = ">= 0.8"
}
/*
# Find the latest Amazon Linux 2 AMI
data "aws_ssm_parameter" "amazon_linux_2" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}
data "aws_ami" "ecs_optimized_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}
output ami {
  value = data.aws_ami.ecs_optimized_ami
}
*/

#Create EC2 into Region and subnet received as param
resource "tls_private_key"      "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair"         "generated_key" {
  key_name   = "${var.project}-${var.region}-keyPair"
  public_key = tls_private_key.private_key.public_key_openssh
  tags = merge(
    local.tags,
    {Name        = "${var.project}-kp-${var.region}-${var.environment}" }
    )

}
resource "local_file"           "my-keys" {
  content = tls_private_key.private_key.private_key_pem
  filename = "${path.module}/files/${var.project}-${var.region}-private-key.pem"
}
resource "aws_security_group"   "customer_securitygrp" {
  vpc_id = var.vpc
  name        = "fortinet-security-grp"
  description = "fortinet-security-grp"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # SSH access from anywhere
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # All TCP traffic from anywhere
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]  # All ICMP traffic from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
  }
  tags = merge(
    local.tags,
    {Name        = "${var.project}-sg-${var.region}-${var.environment}" }
  )
}
resource "aws_instance"         "fortinet" {
  ami               = "ami-06ca0241025c68ab0" #Fortinet without configuration
  availability_zone = "${var.aws_region}a" //"${module.vpc.availability_zones[0]}"
  instance_type     = "t2.small"
  associate_public_ip_address = "false"
  key_name          = aws_key_pair.generated_key.key_name
  subnet_id         = var.subnet
  security_groups   = [aws_security_group.customer_securitygrp.id]
  source_dest_check = "false"
  user_data         = var.ec2_user_data
  tags = merge(
    local.tags,
    {Name        = "${var.project}-ec2-firewall-${var.region}-${var.environment}" }
  )
}
resource "aws_eip"              "eip" {
  domain         = "vpc"
  tags = merge(
    local.tags,
    {Name        = "${var.project}-ec2-fierewall-${var.region}-${var.environment}" }
  )
}
resource "aws_eip_association"  "eip_assoc" {
  instance_id   = aws_instance.fortinet.id #aws_instance.fortinet.id
  allocation_id = aws_eip.eip.id
}
