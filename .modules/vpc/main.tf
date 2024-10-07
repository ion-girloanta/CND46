provider "aws" {
  region = var.aws_region
}
data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}
locals {
  tags = {
    Environment = "${var.project}"
    Project = "${var.project}"
    CreatedOn = formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())
  }
  myIp = "${chomp(data.http.myip.response_body)}"
}
terraform {
  required_version = ">= 0.8"
}

#Create VPC over two AZ's with three subnets Public,Private and DB
resource "aws_vpc" "vpc" {
  cidr_block           = "${cidrsubnet(var.cidr_block, 0, 0)}"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(
      local.tags,
      {Name = "${var.project}-vpc-${var.env_name}"}
  )
}
resource "aws_internet_gateway"         "internet_gateway" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = merge(
    local.tags,
    {    Name        = "${var.project}-IGW-${var.env_name}"})
}
resource "aws_default_route_table"      "default-rtab" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = merge(
  local.tags,
  {    Name        = "${var.project}-default-RT-${var.env_name}"})

}

resource "aws_subnet"                   "public_subnet1" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = cidrsubnet(var.cidr_block, 4,0)
  availability_zone       = "${element(var.availability_zones[var.aws_region],0)}"
  map_public_ip_on_launch = true

  tags = merge(
    local.tags,
    {Name        = "${var.project}-public-${element(var.availability_zones[var.aws_region],0)}"})
}
resource "aws_subnet"                   "public_subnet2" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = cidrsubnet(var.cidr_block, 4,1)
  availability_zone       = "${element(var.availability_zones[var.aws_region],1)}"
  map_public_ip_on_launch = true
  tags = merge(
    local.tags,
    {Name        = "${var.project}-public-${element(var.availability_zones[var.aws_region],1)}"})
}
resource "aws_subnet"                   "public_subnet3" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = cidrsubnet(var.cidr_block, 4,2)
  availability_zone       = "${element(var.availability_zones[var.aws_region],2)}"
  map_public_ip_on_launch = true

  tags = merge(
  local.tags,
  {Name        = "${var.project}-public-${element(var.availability_zones[var.aws_region],2)}"})
}

resource "aws_subnet"                   "private_subnet1" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = cidrsubnet(var.cidr_block, 4,3)
  availability_zone       = "${element(var.availability_zones[var.aws_region],0)}"
  map_public_ip_on_launch = false
  tags = merge(
    local.tags,
    {Name        = "${var.project}-private-${element(var.availability_zones[var.aws_region],0)}"
  })
}
resource "aws_subnet"                   "private_subnet2" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = cidrsubnet(var.cidr_block, 4,4)
  availability_zone       = "${element(var.availability_zones[var.aws_region],1)}"
  map_public_ip_on_launch = false
  tags = merge(
    local.tags,
    {Name        = "${var.project}-private-${element(var.availability_zones[var.aws_region],1)}"
  })
}
resource "aws_subnet"                   "private_subnet3" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = cidrsubnet(var.cidr_block, 4,5)
  availability_zone       = "${element(var.availability_zones[var.aws_region],2)}"
  map_public_ip_on_launch = false
  tags = merge(
  local.tags,
  {Name        = "${var.project}-private-${element(var.availability_zones[var.aws_region],2)}"
  })
}

resource "aws_subnet"                   "db_subnet1" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = cidrsubnet(var.cidr_block, 4,6)
  availability_zone       = "${element(var.availability_zones[var.aws_region],0)}"
  map_public_ip_on_launch = false
  tags = merge(
    local.tags,
    {Name        = "${var.project}-db-${element(var.availability_zones[var.aws_region],0)}"
  })
}
resource "aws_subnet"                   "db_subnet2" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = cidrsubnet(var.cidr_block, 4,7)
  availability_zone       = "${element(var.availability_zones[var.aws_region],1)}"
  map_public_ip_on_launch = false
  tags = merge(
    local.tags,
    {Name        = "${var.project}-db-${element(var.availability_zones[var.aws_region],1)}"
  })
}
resource "aws_subnet"                   "db_subnet3" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = cidrsubnet(var.cidr_block, 4,8)
  availability_zone       = "${element(var.availability_zones[var.aws_region],2)}"
  map_public_ip_on_launch = false
  tags = merge(
  local.tags,
  {Name        = "${var.project}-db-${element(var.availability_zones[var.aws_region],2)}"
  })
}

resource "aws_route_table"              "public_route_table" {
  vpc_id = "${aws_vpc.vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = merge(
  local.tags,
  {Name        = "${var.project}-public-RT--${var.env_name}"
  })
}
resource "aws_route_table"              "private_route_table" {
  vpc_id = "${aws_vpc.vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id= aws_nat_gateway.nat_gw.id
  }
  tags = merge(
    local.tags,
    {Name        = "${var.project}-private-RT-${var.env_name}"
    })
}

resource "aws_route_table_association"  "public_routing_table1" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = "${aws_route_table.public_route_table.id}"
}
resource "aws_route_table_association"  "public_routing_table2" {
  subnet_id      = aws_subnet.public_subnet2.id
  route_table_id = "${aws_route_table.public_route_table.id}"
}
resource "aws_route_table_association"  "public_routing_table3" {
  subnet_id      = aws_subnet.public_subnet3.id
  route_table_id = "${aws_route_table.public_route_table.id}"
}

resource "aws_route_table_association"  "private_routing_table1" {
  subnet_id      = aws_subnet.private_subnet1.id
  route_table_id = aws_route_table.private_route_table.id
}
resource "aws_route_table_association"  "private_routing_table2" {
  subnet_id      = aws_subnet.private_subnet2.id
  route_table_id = aws_route_table.private_route_table.id
}
resource "aws_route_table_association"  "private_routing_table3" {
  subnet_id      = aws_subnet.private_subnet3.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association"  "db_routing_table1" {
  subnet_id      = aws_subnet.db_subnet1.id
  route_table_id = aws_route_table.private_route_table.id
}
resource "aws_route_table_association"  "db_routing_table2" {
  subnet_id      = aws_subnet.db_subnet2.id
  route_table_id = aws_route_table.private_route_table.id
}
resource "aws_route_table_association"  "db_routing_table3" {
  subnet_id      = aws_subnet.db_subnet3.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_security_group"           "sg_nat" {
  name        = "${var.project}-nat-sg-${var.project}"
  description = "${var.project} nat security group"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    from_port         = 3389
    to_port           = 3389
    protocol          = "tcp"
    cidr_blocks       = ["${var.myIp}/32"] //["0.0.0.0/0"]
  } #allow rdp

  ingress {
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    cidr_blocks       = ["${var.myIp}/32"] //["0.0.0.0/0"] aws_vpc.vpc.cidr_block
  } #allow ssh

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    #prefix_list_ids = [aws_vpc_endpoint.my_endpoint.prefix_list_id]
  }

  tags = merge(
  local.tags,
  {Name = "${var.project}-nat-sg-${var.project}"})
}
resource "aws_security_group"           "sg_private" {
  name        = "${var.project}-private-sg-${var.project}"
  description = "${var.project} private security group"
  vpc_id = "${aws_vpc.vpc.id}"

    ingress {
      from_port         = 3389
      to_port           = 3389
      protocol          = "tcp"
      cidr_blocks       = ["${aws_nat_gateway.nat_gw.private_ip}/32"] //["0.0.0.0/0"]

    } #allow rdp from nat

    ingress {
      from_port         = 22
      to_port           = 22
      protocol          = "tcp"
      cidr_blocks       = ["${aws_nat_gateway.nat_gw.private_ip}/32"] //["0.0.0.0/0"] aws_vpc.vpc.cidr_block
    } #allow ssh from nat

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    #prefix_list_ids = [aws_vpc_endpoint.my_endpoint.prefix_list_id]
  }

  tags = merge(
  local.tags,
  {Name = "${var.project}-private-sg-${var.project}"})
}

resource "aws_eip"                      "eip" {
  domain   = "vpc"
  tags = merge(
  local.tags,
  {name = "${var.project}-eip"}
  )
  lifecycle {
    ignore_changes = [
      tags["CreatedOn"],
    ]
  }

}   // elastic ip for the nat gateway
resource "aws_nat_gateway"              "nat_gw" {
  //Error: creating EC2 NAT Gateway: InvalidParameterCombination: Secondary allocation Ids is a required parameter when secondary private Ip addresses parameter is set for NAT Gateway with Connectivity Type public.
  allocation_id                   = aws_eip.eip.id
  subnet_id                       = aws_subnet.public_subnet1.id
  //  secondary_private_ip_addresses  = ["10.0.10.5"]
  connectivity_type               = "public"
  tags = merge(
  local.tags,
  {name = "${var.project}-nat-gw"}
  )
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

