variable "environment" {
  description = "A logical name that will be used as prefix and tag for the created resources."
  type        = string
  default     = "cnd46"
}

variable "env_name" {
  description = "A logical name that will be used as prefix and tag for the created resources."
  type        = string
  default     = "1"
}

variable "project" {
  description = "A logical name that will be used as prefix and tag for the created resources."
  type        = string
  default     = "cnd46"
}

variable "aws_region" {
  type        = string
  description = "The Amazon region."
  default     = "il-central-1"
}

variable "aws_profile" {
  description = "The AWS Profile"
  default="blue-bank"
}

variable "cidr_block" {
  description = "The CDIR block used for the VPC."
  default     = "10.0.0.0/32"
}

variable "availability_zones" {
  type = map

  default = {
    us-east-1      = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"]
    us-east-2      = ["us-east-2a", "eu-east-2b", "eu-east-2c"]
    us-west-1      = ["us-west-1a", "us-west-1c"]
    us-west-2      = ["us-west-2a", "us-west-2b", "us-west-2c"]
    ca-central-1   = ["ca-central-1a", "ca-central-1b"]
    eu-west-1      = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
    eu-west-2      = ["eu-west-2a", "eu-west-2b"]
    eu-central-1   = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
    ap-south-1     = ["ap-south-1a", "ap-south-1b"]
    sa-east-1      = ["sa-east-1a", "sa-east-1c"]
    ap-northeast-1 = ["ap-northeast-1a", "ap-northeast-1c"]
    ap-southeast-1 = ["ap-southeast-1a", "ap-southeast-1b"]
    ap-southeast-2 = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
    ap-northeast-1 = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
    ap-northeast-2 = ["ap-northeast-2a", "ap-northeast-2c"]
    il-central-1   = ["il-central-1a", "il-central-1b", "il-central-1c"]
  }
}

variable "create_private_subnets" {
  description = "If true create a private subnet for each availability zone including a NAT gateway."
  default     = "true"
}

variable "create_eip" {
  description = "If true create a private subnet for each availability zone including a NAT gateway."
  default     = "false"
}

variable "create_nat" {
  description = "If true create a private subnet for each availability zone including a NAT gateway."
  default     = "false"
}

variable "myIp" {
  description = "If true create a private subnet for each availability zone including a NAT gateway."
  default     = "0/0/0/0"
}

variable "create_private_hosted_zone" {
  description = "If true a privated hosted zone is created."
  default     = "false"
}

variable "public_subnet_map_public_ip_on_launch" {
  description = "Set the default behavior for instances created in the VPC. If true by default a publi ip will be assigned."
  default     = "false"
}
