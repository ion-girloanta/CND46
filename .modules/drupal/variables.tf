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
variable "vpc_id" {
  description = "The VPC id"
  default = null
}
variable "public_subnets" {
  description = "The public subnets id"
  default = []
}
variable "private_subnets" {
  description = "The private subnets id"
  default = []
}
variable "public_subnets_cidr" {
  description = "The public subnets id"
  default = []
}
variable "private_subnets_cidr" {
  description = "The private subnets id"
  default = []
}
variable "db_subnets" {
  description = "The private subnets id"
  default = []
}
variable "ec2_user_data" {
}
variable "route53_zone_id" {
  default = null
}
# Variables
variable "VpcCIDR" {
  default = "10.192.0.0/16"
}
variable "ClusterName" {
  default = "drupalonefs"
}
variable "Image" {
  default = "drupal"  #drupal 11
}
variable "MinCapacity" {
  default = 1
}
variable "MaxCapacity" {
  default = 5
}
variable "EnvironmentName" {
  default = "Test"
}
variable "DBAdminUsername" {
  default = "admin"
}
variable "DBPassword" {
  default = "securepassword123"
}
variable "PerformanceMode" {
  default = "generalPurpose"
}
variable "EfsProvisionedThroughputInMibps" {
  default = 0
}
variable "ThroughputMode" {
  default = "bursting"
}
variable "MinimumAuroraCapacityUnit" {
  default = 1
}
variable "MaximumAuroraCapacityUnit" {
  default = 16
}
