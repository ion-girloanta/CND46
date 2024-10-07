variable "environment" {
  description = "A logical name that will be used as prefix and tag for the created resources."
  type        = string
  default     = "cnd46"
}

variable "region" {
  description = "Region"
  type        = string
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

variable "vpc" {
  description = "The VPC id"
}

variable "subnet" {
  description = "The VPC id"
}

variable "ec2_user_data" {

}