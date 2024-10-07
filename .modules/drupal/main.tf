#https://spinspire.com/article/deploying-drupal-site-aws-using-terraform
provider "aws" {
  region = var.aws_region
}
data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}
locals {
  cidr_block = "10.1.0.0/16"
  tags = {
    Environment = "${var.project}"
    Project = "${var.project}"
    CreatedOn = formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())
  }
  myIp = "${chomp(data.http.myip.response_body)}"
}

resource "aws_route53_record" "us_site" {
  zone_id = var.route53_zone_id
  name    = "${var.region}1.ion-g.org"
  type    = "A"

  alias {
    name                   = aws_alb.alb.dns_name     #aws_cloudformation_stack.example.outputs["ALBEndpoint"] #aws_lb.ecs_lb.dns_name
    zone_id                = var.route53_zone_id      #"il-central-1" #aws_lb.ecs_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_cloudformation_stack" "example" {
  name = "cnd46CF"
  capabilities = ["CAPABILITY_IAM",
    "CAPABILITY_NAMED_IAM",
    "CAPABILITY_AUTO_EXPAND"]
  parameters = {
    VpcCIDR = local.cidr_block
    ClusterName = "${var.project}"
    DBAdminUsername = "a${random_string.rds_username.result}"
    DBPassword = random_string.rds_password.result
    EfsProvisionedThroughputInMibps = 0
    EnvironmentName ="${var.project}"
    Image = "drupal:8-apache"
    MaxCapacity = 5
    MaximumAuroraCapacityUnit = 16
    MinCapacity = 1
    MinimumAuroraCapacityUnit = 1
    PerformanceMode = "generalPurpose"
    PrivateSubnet1CIDR = cidrsubnet(local.cidr_block, 4,0)
    PrivateSubnet2CIDR = cidrsubnet(local.cidr_block, 4,1)
    PrivateSubnet3CIDR = cidrsubnet(local.cidr_block, 4,2)
    PublicSubnet1CIDR  = cidrsubnet(local.cidr_block, 4,3)
    PublicSubnet2CIDR  = cidrsubnet(local.cidr_block, 4,4)
    PublicSubnet3CIDR  = cidrsubnet(local.cidr_block, 4,5)
    ThroughputMode = "bursting"
    }
  template_body = file("${path.module}/files/template.yaml")
}
resource "aws_cloudwatch_log_group" "task_log" {
  name              = "/ecs/cnd46taskdefinition/${var.project}-Container"   #"/aws/ecs/${var.project}-drupal-${var.env_name}"
  retention_in_days = 1

  tags = merge(
  local.tags,
  {Name        = "${var.project}-drupal-loggroup-${var.env_name}"
  })
}
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.project}-ecs-cluster-${var.env_name}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = merge(
    local.tags,
    {Name        = "${var.project}-ecs-cluster-${var.env_name}-${var.env_name}"
  })

}
resource "aws_ecs_service" "ecs_service" {
  name            = "${var.ClusterName}-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.drupal_task.arn
  desired_count   = var.MinCapacity
  launch_type     = "FARGATE"
  wait_for_steady_state = true
  enable_execute_command  = false
  depends_on = [aws_alb_listener.front_end]

  network_configuration {
    subnets          = [var.private_subnets[0],var.private_subnets[1],var.private_subnets[2]]
    security_groups  = [aws_security_group.container_sg.id,aws_security_group.efs_sg.id ]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.app.arn
    container_name   = "drupal"
    container_port   = 80
  }

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  propagate_tags = "SERVICE"
}
resource "aws_ecs_task_definition" "drupal_task" {
  family                = "${var.project}-task-${var.env_name}"
  network_mode          = "awsvpc"
  requires_compatibilities = ["EC2","FARGATE"]
  cpu                   = "512"
  memory                = "1024"
  execution_role_arn    = aws_iam_role.execution_role.arn
  task_role_arn         = aws_iam_role.execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "initcontainer"
      image     = "drupal:8-apache" #var.Image
      essential = false
      logConfiguration: {
        logDriver: "awslogs",
        options: {
          awslogs-group: aws_cloudwatch_log_group.task_log.name,
          awslogs-region: "il-central-1",
          awslogs-stream-prefix: "initcontainer"
        }
      }
      entryPoint: [
        "sh -c",
        "cp -prR /var/www/html/sites/* /mnt"
      ],
      mountPoints = [
        {
          sourceVolume  = "efs-sites"
          containerPath = "/mnt"
        }
      ]
    },
    {
      name      = "drupal"  #
      image     = "drupal:8-apache"  #var.Image
      essential = true
      dependsOn = [
        {
          "containerName": "initcontainer",
          "condition": "COMPLETE"
        }
      ]
      logConfiguration: {
        logDriver: "awslogs",
        options: {
          awslogs-group: aws_cloudwatch_log_group.task_log.name,
          awslogs-region: "il-central-1",
          awslogs-stream-prefix: "task"
        }
      }
      mountPoints = [
        {
          sourceVolume  = "efs-sites"
          containerPath = "/var/www/html/sites/"
        },
        {
          sourceVolume  = "efs-modules"
          containerPath = "/var/www/html/modules/"
        },
        {
          sourceVolume  = "efs-themes"
          containerPath = "/var/www/html/themes/"
        },
        {
          sourceVolume  = "efs-modules"
          containerPath = "/var/www/html/profiles/"
        }
      ]
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80  # Optional for Fargate, defaults to the same as containerPort
          protocol      = "tcp"
        }
      ]
    }
  ])

  volume {
    name = "efs-sites"
    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.efs.id
      root_directory          = "/"
      transit_encryption      = "ENABLED"
      authorization_config {
        iam = "ENABLED"
        access_point_id = aws_efs_access_point.sites.id
      }
    }
  }

  volume {
    name = "efs-modules"
    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.efs.id
      root_directory          = "/"
      transit_encryption      = "ENABLED"

      authorization_config {
        iam = "ENABLED"
        access_point_id = aws_efs_access_point.modules.id
      }

    }
  }

  volume {
    name = "efs-themes"
    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.efs.id
      root_directory          = "/"
      transit_encryption      = "ENABLED"

      authorization_config {
        iam = "ENABLED"
        access_point_id = aws_efs_access_point.themes.id
      }

    }
  }

  volume {
    name = "efs-profiles"
    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.efs.id
      root_directory          = "/"
      transit_encryption      = "ENABLED"

     authorization_config {
       iam = "ENABLED"
       access_point_id = aws_efs_access_point.profiles.id
     }

    }
  }

  tags = merge(
    local.tags,
    {Name        = "${var.project}-drupal-task-${var.env_name}"
  })

}
/*
resource "aws_ecs_task_definition" "drupal_task_old" {
  family                = "${var.project}-task-${var.env_name}"
  network_mode          = "awsvpc"
  requires_compatibilities = ["EC2","FARGATE"]
  cpu                   = "512"
  memory                = "1024"
  execution_role_arn    = aws_iam_role.execution_role.arn
  task_role_arn         = aws_iam_role.execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "initcontainer"
      image     = "drupal:8-apache" #var.Image
      essential = false
      logConfiguration: {
        logDriver: "awslogs",
        options: {
          awslogs-group: aws_cloudwatch_log_group.task_log.name,
          awslogs-region: "il-central-1",
          awslogs-stream-prefix: "initcontainer"
        }
      }
      entryPoint: [
        "sh -c",
        "cp -prR /var/www/html/sites/* /mnt"
      ],
      mountPoints = [
        {
          sourceVolume  = "efs-sites"
          containerPath = "/mnt"
        }
      ]
    },
    {
      name      = "drupal"  #
      image     = "drupal:8-apache"  #var.Image
      essential = true
      dependsOn = [
        {
          "containerName": "initcontainer",
          "condition": "COMPLETE"
        }
      ]
      logConfiguration: {
        logDriver: "awslogs",
        options: {
          awslogs-group: aws_cloudwatch_log_group.task_log.name,
          awslogs-region: "il-central-1",
          awslogs-stream-prefix: "task"
        }
      }
      mountPoints = [
        {
          sourceVolume  = "efs-sites"
          containerPath = "/var/www/html/sites/"
        },
        {
          sourceVolume  = "efs-modules"
          containerPath = "/var/www/html/modules/"
        },
        {
          sourceVolume  = "efs-themes"
          containerPath = "/var/www/html/themes/"
        },
        {
          sourceVolume  = "efs-modules"
          containerPath = "/var/www/html/profiles/"
        }
      ]
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80  # Optional for Fargate, defaults to the same as containerPort
          protocol      = "tcp"
        }
      ]
    }
  ])

  volume {
    name = "efs-sites"
    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.efs.id
      root_directory          = "/"
      transit_encryption      = "ENABLED"
      authorization_config {
        iam = "ENABLED"
        access_point_id = aws_efs_access_point.sites.id
      }
    }
  }

  volume {
    name = "efs-modules"
    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.efs.id
      root_directory          = "/"
      transit_encryption      = "ENABLED"

      authorization_config {
        iam = "ENABLED"
        access_point_id = aws_efs_access_point.modules.id
      }

    }
  }

  volume {
    name = "efs-themes"
    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.efs.id
      root_directory          = "/"
      transit_encryption      = "ENABLED"

      authorization_config {
        iam = "ENABLED"
        access_point_id = aws_efs_access_point.themes.id
      }

    }
  }

  volume {
    name = "efs-profiles"
    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.efs.id
      root_directory          = "/"
      transit_encryption      = "ENABLED"

      authorization_config {
        iam = "ENABLED"
        access_point_id = aws_efs_access_point.profiles.id
      }

    }
  }

  tags = merge(
  local.tags,
  {Name        = "${var.project}-drupal-task-${var.env_name}"
  })

}
*/
resource "aws_efs_file_system" "efs" {
  encrypted         = true
  performance_mode  = var.PerformanceMode
  throughput_mode   = var.ThroughputMode
  provisioned_throughput_in_mibps = var.EfsProvisionedThroughputInMibps

  tags = merge(
    local.tags,
    {Name        = "${var.project}-efs-${var.env_name}"
  })
}
resource "aws_efs_access_point" "sites" {
  file_system_id = aws_efs_file_system.efs.id
  posix_user {
    uid = 33 #82
    gid = 33 #82
  }
  root_directory {
    creation_info {
      owner_uid   = 33 #82
      owner_gid   = 33 #82
      permissions = "0755"
    }
    path = "/sites"
  }
  tags = merge(
    local.tags,
    {Name        = "sites"
  })
}
resource "aws_efs_access_point" "themes" {
  file_system_id = aws_efs_file_system.efs.id
  posix_user {
    uid = 33 #82
    gid = 33 #82
  }
  root_directory {
    creation_info {
      owner_uid   = 33 #82
      owner_gid   = 33 #82
      permissions = 755
    }
    path = "/themes"
  }
  tags = merge(
    local.tags,
    {Name        = "themes"
  })
}
resource "aws_efs_access_point" "profiles" {
  file_system_id = aws_efs_file_system.efs.id
  posix_user {
    uid = 33 #82
    gid = 33 #82
  }
  root_directory {
    creation_info {
      owner_uid   = 33 #82
      owner_gid   = 33 #82
      permissions = 755
    }
    path = "/profiles"
  }
  tags = merge(
    local.tags,
    {Name        = "profiles"
  })
}
resource "aws_efs_access_point" "modules" {
  file_system_id = aws_efs_file_system.efs.id

  posix_user {
    uid = 33 #82
    gid = 33 #82
  }
  root_directory {
    creation_info {
      owner_uid   = 33 #82
      owner_gid   = 33 #82
      permissions = "0755"
    }
    path = "/modules"
  }
  tags = merge(
    local.tags,
    {Name        = "modules"
  })
}
resource "aws_efs_mount_target" "efs_mount_target1" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = var.public_subnets[0]
  security_groups = [aws_security_group.efs_sg.id]
}
resource "aws_efs_mount_target" "efs_mount_target2" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = var.public_subnets[1]
  security_groups = [aws_security_group.efs_sg.id]
}
#ToDo add autoscale role

resource "aws_iam_role" "execution_role" {
  name = "${var.ClusterName}-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = [
          "ecs-tasks.amazonaws.com"
        ]}
    }]
  })
}
resource "aws_iam_policy" "ecs_task_execution_policy" {
  name        = "ecs-task-execution-policy"
  description = "Policy for ECS Task Execution Role"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientRootAccess",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:DescribeMountTargets",

          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs",

          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",

          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:PutLogEventsBatch",
          "logs:CreateLogStream",
          "logs:PutLogEvents"

        ],
        "Resource": "*"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "ecs_task_execution_attach" {
  role       = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_policy.arn
}

resource "aws_security_group" "container_sg" {
  vpc_id = var.vpc_id

  ingress =[
    {# Access from load balancer
      description      = "HTTP"
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = [aws_security_group.alb_sg.id]
      self = false
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      cidr_blocks = [] #TODO 0.0.0.0/0delete rule from anywhere
    }
  ]

  egress = [
    { # Access to anywhere
      description      = "HTTPS"
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = false
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      cidr_blocks = ["0.0.0.0/0"]
    },
    {# Access to DB
      description      = "DB"
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = false
      protocol    = "tcp"
      from_port   = 3306
      to_port     = 3306
      cidr_blocks = [var.VpcCIDR]
    },
    {# Access to EFS
      description      = "NFS"
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = false
      protocol    = "tcp"
      from_port   = 2049
      to_port     = 2049
      cidr_blocks = [var.VpcCIDR]
    }
  ]

  tags = {
    Name = "${var.ClusterName}-container-sg"
  }
}
resource "aws_security_group" "alb_sg" {
  vpc_id = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = [var.VpcCIDR]
  }

  tags = merge(
    local.tags,
    {Name        = "${var.project}-alb-sg-${var.env_name}"
  })

}
resource "aws_security_group" "efs_sg" {
  vpc_id =var.vpc_id

  ingress {
    description = "NFS"
    protocol    = "tcp"
    from_port   = 2049
    to_port     = 2049
    cidr_blocks = [var.VpcCIDR]
  }

  egress {
    description = "NFS"
    protocol    = "tcp"
    from_port   = 2049
    to_port     = 2049
    cidr_blocks = [var.VpcCIDR]
  }

  tags = merge(
    local.tags,
    {Name        = "${var.project}-efs-sg-${var.env_name}"
  })

}
resource "aws_security_group" "rds_sg" {
  name        = "il-rds-sg"
  description = "Allow MySQL traffic for RDS in IL"
  vpc_id      = var.vpc_id

  ingress {
    description = "MYSQL/Aurora"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.VpcCIDR]
  }

  egress {
    description = "MYSQL/Aurora"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.VpcCIDR]
  }

  tags = {
    Name = "IL-RDS-SG"
  }
}
resource "aws_db_subnet_group" "subnet_group" {
  name        = "il-rds-subnet-group"
  description = "Subnet group for RDS in IL region"
  subnet_ids  = var.db_subnets

  tags = {
    Name = "IL-RDS-Subnet-Group"
  }
}

resource "random_string" "rds_username" {
  length = 12
  special = false
}
resource "random_string" "rds_password" {
  length           = 12
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
output "rds_username" {
  value = random_string.rds_password.result
}
/*
resource "aws_db_instance" "rds" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  #name                 = "drupaldb"
  username             = "admin"    #random_string.rds_username.result
  password             = "password" #random_string.rds_password.result
  publicly_accessible  = false
  multi_az             = true
  skip_final_snapshot  = true

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.subnet_group.id

  tags = {
    Name = "Drupal-DB"
  }
}
*/
resource "aws_alb" "alb" {
  name        = "cb-load-balancer"
  subnets         = [var.public_subnets[0],var.public_subnets[1],var.public_subnets[2]]
  security_groups = [aws_security_group.alb_sg.id]
}
resource "aws_alb_target_group" "app" {
  name        = "cb-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }
}
resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_alb.alb.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.app.id
    type             = "forward"
  }
}

#AutoScalingRole AWS::IAM::Role
#AutoScalingPolicy AWS::ApplicationAutoScaling::ScalingPolicy
#AutoScalingTarget AWS::ApplicationAutoScaling::ScalableTarget