terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

data "aws_subnet_ids" "default" {
  vpc_id = aws_default_vpc.default.id
}

locals {
  user_data               = <<EOF
pip3 install awscli
aws s3 sync s3://${aws_s3_bucket.backups.id}/ /home/ec2-user/valheim/
(crontab -l 2>/dev/null; echo "${var.world_backup_schedule} aws s3 sync /home/ec2-user/valheim/ s3://${aws_s3_bucket.backups.id}/") | crontab -
EOF
  instance_policy_actions = <<EOF
	"s3:Put*",
	"s3:List*",
        "s3:Get*",
        "s3:Delete*",
EOF
}

module "ecs_cluster" {
  source = "github.com/kpenfound/ecs-cluster?ref=1.2.2"

  region                        = var.region
  ecs_ami                       = var.ecs_ami
  ecs_instance_key              = var.key_name
  ecs_instance_type             = var.instance_type
  cluster_name                  = var.cluster_name
  vpc_id                        = aws_default_vpc.default.id
  subnets                       = data.aws_subnet_ids.default.ids
  extra_user_data               = local.user_data
  extra_instance_policy_actions = local.instance_policy_actions
}

resource "aws_security_group_rule" "public_access" {
  type              = "ingress"
  from_port         = 2456
  to_port           = 2458
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.ecs_cluster.sg_id
}

resource "aws_ecs_service" "service" {
  name            = var.task_name
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }
}

resource "aws_ecs_task_definition" "task" {
  family = var.task_name

  container_definitions = <<DEFINITION
[
  {
    "cpu": ${var.task_cpu},
    "environment": [
        {
          "name": "NAME",
          "value": "${var.world_name}"
        },
        {
          "name": "WORLD",
          "value": "${var.world_name}"
        },
        {
          "name": "PASSWORD",
          "value": "${var.world_password}"
        },
        {
          "name": "PUBLIC",
          "value": "${var.world_public}"
        },
        {
          "name": "TZ",
          "value": "${var.world_tz}"
        },
        {
          "name": "AUTO_BACKUP",
          "value": "${var.world_backup}"
        },
        {
          "name": "AUTO_BACKUP_SCHEDULE",
          "value": "${var.world_backup_schedule}"
        },
        {
          "name": "AUTO_BACKUP_REMOVE_OLD",
          "value": "${var.world_backup_remove_old}"
        },
        {
          "name": "AUTO_BACKUP_DAYS_TO_LIVE",
          "value": "${var.world_backup_days_to_live}"
        },
        {
          "name": "AUTO_UPDATE",
          "value": "${var.world_update}"
        },
        {
          "name": "AUTO_UPDATE_SCHEDULE",
          "value": "${var.world_update_schedule}"
        },
        {
          "name": "AUTO_BACKUP_ON_UPDATE",
          "value": "1"
        },
        {
          "name": "AUTO_BACKUP_ON_SHUTDOWN",
          "value": "1"
        }
    ],
    "essential": true,
    "image": "${var.docker_image}",
    "memoryReservation": ${var.task_memory},
    "name": "${var.task_name}",
    "portMappings": [
        {
            "containerPort": 2456,
            "hostPort": 2456,
            "protocol": "udp"
        },
        {
            "containerPort": 2457,
            "hostPort": 2457,
            "protocol": "udp"
        },
        {
            "containerPort": 2458,
            "hostPort": 2458,
            "protocol": "udp"
        }
    ],
    "mountPoints": [
        {
            "containerPath": "/home/steam/.config/unity3d/IronGate/Valheim",
            "sourceVolume": "saves"
        },
        {
            "containerPath": "/home/steam/valheim",
            "sourceVolume": "server"
        },
        {
            "containerPath": "/home/steam/backups",
            "sourceVolume": "backups"
        }
    ]
  }
]
DEFINITION

  volume {
    name      = "saves"
    host_path = "/home/ec2-user/valheim/saves"
  }

  volume {
    name      = "server"
    host_path = "/home/ec2-user/valheim/server"
  }

  volume {
    name      = "backups"
    host_path = "/home/ec2-user/valheim/backups"
  }
}

resource "aws_s3_bucket" "backups" {
  bucket_prefix = "valheim-backup-${lower(var.world_name)}"
  acl           = "private"
}
