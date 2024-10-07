#
#https://aws.amazon.com/blogs/storage/deploy-serverless-drupal-applications-using-aws-fargate-and-amazon-efs/
#

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}
locals {
  tags = {
    Environment = "${var.environment}"
    Project     = "${var.project}"
    CreatedOn   = formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())
  }
  myIp          = "${chomp(data.http.myip.response_body)}"
  env_name      = "cnd46"
}

#Implement network with vpn S2S from Israel and Transit GW to Europe and USA
##################################################

module    "vpc-Israel" {
  source = "./.modules/vpc"
  env_name = "IL"
  cidr_block = "10.0.0.0/16"
  myIp = local.myIp
  project = var.project
  environment = "" #var.environment
  aws_region = "il-central-1"
} # "10.0.0.0/16" Create VPC in Israel with 6 subnets (Public, Private, DB), NGW and IWG
module    "vpc-EU" {
  source = "./.modules/vpc"
  env_name = "EU"
  cidr_block = "10.1.0.0/16"
  myIp = local.myIp
  project = var.project
  environment = "" #var.environment
  aws_region = "eu-central-1"
} # "10.1.0.0/16" Create VPC in Frankfurt with 6 subnets (Public, Private, DB), NGW and IWG
module    "vpc-US" {
  source = "./.modules/vpc"
  env_name = "US"
  cidr_block = "10.2.0.0/16"
  myIp = local.myIp
  project = var.project
  environment = "" #var.environment
  aws_region = "us-east-1"
} # "10.2.0.0/16" Create VPC in N. Virginia with 6 subnets (Public, Private, DB), NGW and IWG
module    "drupal-Israel"{
  source = "./.modules/drupal"
  env_name = "prod"
  ClusterName = "drupal-il"
  cidr_block = "10.2.0.0/16"
  project = var.project
  environment = "" #var.environment
  aws_region = "il-central-1"
  ec2_user_data = ""
  region = "il"
  db_subnets = module.vpc-Israel.db_subnets
  public_subnets = module.vpc-Israel.public_subnets
  private_subnets = module.vpc-Israel.private_subnets
  public_subnets_cidr = module.vpc-Israel.public_subnets_cidr
  private_subnets_cidr = module.vpc-Israel.private_subnets_cidr
  route53_zone_id = var.ion_g_zone_id
  vpc_id = module.vpc-Israel.vpc_id

}

# VPN S2S Israel (Tel Aviv) il-central-1
##################################################
module    "ec2-Fortinet" {
  source = "./.modules/ec2"
  subnet = module.vpc-EU.public_subnets[0]
  vpc = module.vpc-EU.vpc_id
  region = "eu"
  aws_region = "eu-central-1"
  project = "${var.project}"
  ec2_user_data = ""
  env_name = local.env_name
  environment = ""   #var.environment
} # Create EC2 Fortigate Instance  Frankfurt EU central region
resource  "aws_vpn_gateway" "israel_vgw" {
  provider          = aws.Israel
  vpc_id            = module.vpc-Israel.vpc_id        #"<Israel_VPC_ID>"
  amazon_side_asn   = "64512"
  tags = merge(
    local.tags,
    {Name        = "${var.project}-vgw-IL"})
}
resource  "aws_customer_gateway" "IL_cgw" {
  provider         = aws.Israel
  bgp_asn          = 65000
  ip_address       = module.ec2-Fortinet.public_ip
  type             = "ipsec.1"
  tags = merge(
    local.tags,
    {Name        = "${var.project}-IL-cgw"
  })
}    #represents Fortinet server in Frankfurt
resource  "aws_vpn_connection" "Israel_to_EU" {
  provider          = aws.Israel
  vpn_gateway_id    = aws_vpn_gateway.israel_vgw.id
  customer_gateway_id = aws_customer_gateway.IL_cgw.id
  type              = "ipsec.1"
  static_routes_only = false # Change to true if using static routing
  local_ipv4_network_cidr = "10.1.0.0/16"
  remote_ipv4_network_cidr = "10.0.0.0/16"
  tags = merge(
    local.tags,
    {Name        = "${var.project}-vpn-IL"
  })
}
resource  "aws_route" "Israel_to_eu_route" {
  provider                = aws.Israel
  route_table_id          = module.vpc-Israel.main-route-table
  destination_cidr_block  = "10.1.0.0/16"
  gateway_id              = aws_vpn_gateway.israel_vgw.id
}
resource  "aws_security_group" "vpn_sg" {
  provider    = aws.EU
  name        = "vpn-sg"
  description = "Allow SSH and VPN traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere (adjust as needed)
  }

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"] # Allow OpenVPN traffic
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(
  local.tags,
  {Name        = "${var.project}-eu-vpn-sg"
  })

}

# Create an SQS queue for cross-region updates (FIFO for ordered delivery)
resource "aws_sqs_queue" "queue_region_il" {
  provider = aws.Israel
  name = "purchase-queue-region-a.fifo"
  fifo_queue                  = true
  content_based_deduplication = true

  # Optional configurations for visibility and retention
  visibility_timeout_seconds = 30
  message_retention_seconds  = 86400
  redrive_policy              = jsonencode({
    deadLetterTargetArn       = aws_sqs_queue.dlq_il.arn
    maxReceiveCount           = 5
  })
}
resource "aws_sqs_queue" "dlq_il" {
  provider = aws.Israel
  name = "dlq-il.fifo"
  fifo_queue                = true
  content_based_deduplication = true
}
resource "aws_sqs_queue" "queue_region_EU" {
  provider                    = aws.EU
  name                        = "purchase-queue-region-b.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  visibility_timeout_seconds  = 30
  message_retention_seconds   = 86400
  redrive_policy              = jsonencode({
    deadLetterTargetArn       = aws_sqs_queue.dlq_EU.arn
    maxReceiveCount           = 5
  })
}
resource "aws_sqs_queue" "dlq_EU" {
  provider                    = aws.EU
  name                        = "dlq-EU.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
}
resource "aws_lambda_function" "forward_to_region_b" {
  provider = aws.Israel
  filename      = "./files/forward_to_region_b.zip"
  function_name = "forward_to_region_b"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  environment {
    variables = {
      QUEUE_URL_REGION_B  = aws_sqs_queue.queue_region_EU.id  # SQS queue in Region B
      REGION_A            = "il-central-1"
      REGION_B            = "eu-central-1"
    }
  }
}
resource "aws_lambda_event_source_mapping" "sqs_to_lambda_region_a" {
  provider = aws.Israel
  event_source_arn = aws_sqs_queue.queue_region_il.arn
  function_name    = aws_lambda_function.forward_to_region_b.arn
  batch_size       = 10  # Adjust as needed
  enabled          = true
}
resource "aws_lambda_function" "db_update_region_b" {
  filename      = "./files/db_update_region_b.zip"
  function_name = "db_update_region_b"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  environment {
    variables = {
      DB_HOST     = "your-rds-endpoint",
      DB_USER     = "admin",
      DB_PASSWORD = "password",
      DB_NAME     = "productdb"
    }
  }
}
resource "aws_lambda_event_source_mapping" "sqs_to_lambda_region_b" {
  event_source_arn = aws_sqs_queue.queue_region_EU.arn
  function_name    = aws_lambda_function.db_update_region_b.arn
  batch_size       = 10  # Adjust based on your needs
  enabled          = true
}
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}
resource "aws_iam_role_policy" "lambda_sqs_policy" {
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "sqs:SendMessage"
        ],
        "Resource": aws_sqs_queue.queue_region_EU.arn  # Queue in Region B
      },
      {
        "Effect": "Allow",
        "Action": [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        "Resource": aws_sqs_queue.queue_region_il.arn  # Queue in Region A
      }
    ]
  })
}
resource "aws_iam_role_policy" "lambda_db_update_policy" {
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        "Resource": aws_sqs_queue.queue_region_EU.arn  # Queue in Region B
      },
      {
        "Effect": "Allow",
        "Action": [
          "rds:Connect"
        ],
        "Resource": "*"  # RDS access, adjust this based on your setup
      }
    ]
  })
}

echo "# CND46" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/ion-girloanta/CND46.git
git push -u origin main
