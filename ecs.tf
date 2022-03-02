resource "aws_autoscaling_group" "ecs" {
  name                 = local.world
  min_size             = var.cluster_min_size
  max_size             = var.cluster_max_size
  vpc_zone_identifier  = var.subnets
  launch_configuration = aws_launch_configuration.ecs_instance.name

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_instance_profile" "ecs_instance" {
  name_prefix = "ecs_instance_profile"
  role        = aws_iam_role.ecs_instance_role.name
}

resource "aws_iam_role" "ecs_instance_role" {
  name_prefix = "ecs_instance_role"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": [
        "sts:AssumeRole"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy" "instance_policy" {
  name        = "ecs-instance-policy"
  description = "ECS Instance Policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeTags",
                "ecs:CreateCluster",
                "ecs:DeregisterContainerInstance",
                "ecs:DiscoverPollEndpoint",
                "ecs:Poll",
                "ecs:RegisterContainerInstance",
                "ecs:StartTelemetrySession",
                "ecs:UpdateContainerInstancesState",
                "ecs:Submit*",
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "s3:Put*",
                "s3:List*",
                "s3:Get*",
                "s3:Delete*",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "instance_policy_attach" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = aws_iam_policy.instance_policy.arn
}

resource "aws_launch_configuration" "ecs_instance" {
  name                 = local.world
  image_id             = var.ecs_ami
  instance_type        = var.instance_type
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.ecs_instance.name

  user_data = <<EOF
#!/bin/bash
echo ECS_CLUSTER=${local.world} >> /etc/ecs/ecs.config
yum install -y unzip
curl  -o awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
curl -o awscliv2.sig https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip.sig
gpg --import ${var.awscli_gpg_key}
gpg --verify awscliv2.sig awscliv2.zip
unzip awscliv2.zip
sh ./aws/install
/usr/local/bin/aws s3 sync s3://${aws_s3_bucket.backups.id}/ /home/ec2-user/valheim/
(crontab -l 2>/dev/null; echo "${var.world_backup_schedule} /usr/local/bin/aws s3 sync /home/ec2-user/valheim/ s3://${aws_s3_bucket.backups.id}/") | crontab - 
EOF

  security_groups = [aws_security_group.cluster_instance.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_cluster" "cluster" {
  name = local.world
}

resource "aws_security_group" "cluster_instance" {
  name   = local.world
  vpc_id = local.vpc_id

  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }

  ingress {
    from_port       = "0"
    to_port         = "0"
    protocol        = "-1"
    security_groups = var.allowed_sgs
  }

  ingress {
    from_port   = "2456"
    to_port     = "2458"
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "service" {
  name            = local.world
  cluster         = local.world
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.fivesix.arn
    container_name   = local.world
    container_port   = 2456
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.fiveseven.arn
    container_name   = local.world
    container_port   = 2457
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.fiveeight.arn
    container_name   = local.world
    container_port   = 2458
  }
}

resource "aws_ecs_task_definition" "task" {
  family = local.world

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
        },
        {
          "name": "UPDATE_ON_STARTUP",
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
