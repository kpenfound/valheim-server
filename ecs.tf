resource "aws_autoscaling_group" "ecs" {
  name                 = local.world
  min_size             = 1
  max_size             = 1
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids
  launch_configuration = aws_launch_configuration.ecs_instance.name

  target_group_arns = [
    aws_lb_target_group.fivesix.arn,
    aws_lb_target_group.fiveseven.arn,
    aws_lb_target_group.fiveeight.arn
  ]

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

  assume_role_policy = jsonencode({
    "Version" = "2008-10-17",
    "Statement" = [
      {
        "Sid" = "",
        "Effect" = "Allow",
        "Principal" = {
          "Service" = "ec2.amazonaws.com"
        },
        "Action" = [
          "sts:AssumeRole"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "instance_policy" {
  name        = "ecs-instance-policy"
  description = "ECS Instance Policy"

  policy = jsonencode({
      "Version" = "2012-10-17",
      "Statement": [
          {
              "Effect" = "Allow",
              "Action" = [
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
              "Resource" = "*"
          }
      ]
  })
}

resource "aws_iam_role_policy_attachment" "instance_policy_attach" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = aws_iam_policy.instance_policy.arn
}

resource "aws_launch_configuration" "ecs_instance" {
  name_prefix          = local.world
  image_id             = var.ecs_ami
  instance_type        = var.instance_type
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.ecs_instance.name

  user_data = <<EOF
#!/bin/bash
echo ECS_CLUSTER=${local.world} >> /etc/ecs/ecs.config
yum install -y awscli
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y nginx
systemctl enable nginx
systemctl start nginx
# create backup script from template
# create idle counter script from template
/usr/bin/aws s3 sync s3://${aws_s3_bucket.backups.id}/ /home/ec2-user/valheim/
(crontab -l 2>/dev/null; echo "${var.world_backup_schedule} sh /home/ec2-user/backup.sh") | crontab - 
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
    from_port   = "2456"
    to_port     = "2458"
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
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
}

resource "aws_ecs_task_definition" "task" {
  family = local.world

  container_definitions = jsonencode([
    {
      "cpu"= var.task_cpu,
      "environment" = [
          {
            "name" = "NAME",
            "value" = var.world_name
          },
          {
            "name" = "WORLD",
            "value" = var.world_name
          },
          {
            "name" = "PASSWORD",
            "value" = var.world_password
          },
          {
            "name" = "PUBLIC",
            "value" = var.world_public
          },
          {
            "name" = "TZ",
            "value" = var.world_tz
          },
          {
            "name" = "AUTO_BACKUP",
            "value" = var.world_backup
          },
          {
            "name" = "AUTO_BACKUP_SCHEDULE",
            "value" = var.world_backup_schedule
          },
          {
            "name" = "AUTO_BACKUP_REMOVE_OLD",
            "value" = var.world_backup_remove_old
          },
          {
            "name" = "AUTO_BACKUP_DAYS_TO_LIVE",
            "value" = var.world_backup_days_to_live
          },
          {
            "name" = "AUTO_UPDATE",
            "value" = var.world_update
          },
          {
            "name" = "AUTO_UPDATE_SCHEDULE",
            "value" = var.world_update_schedule
          },
          {
            "name" = "AUTO_BACKUP_ON_UPDATE",
            "value" = "1"
          },
          {
            "name" = "AUTO_BACKUP_ON_SHUTDOWN",
            "value" = "1"
          },
          {
            "name" = "UPDATE_ON_STARTUP",
            "value" = "1"
          }
      ],
      "essential" = true,
      "image" = var.docker_image,
      "memoryReservation" = var.task_memory,
      "name" = local.world,
      "portMappings" = [
          {
              "containerPort" = 2456,
              "hostPort" = 2456,
              "protocol" = "udp"
          },
          {
              "containerPort" = 2457,
              "hostPort" = 2457,
              "protocol" = "udp"
          },
          {
              "containerPort" = 2458,
              "hostPort" = 2458,
              "protocol" = "udp"
          }
      ],
      "mountPoints" = [
          {
              "containerPath" = "/home/steam/.config/unity3d/IronGate/Valheim",
              "sourceVolume" = "saves"
          },
          {
              "containerPath" = "/home/steam/valheim",
              "sourceVolume" = "server"
          },
          {
              "containerPath" = "/home/steam/backups",
              "sourceVolume" = "backups"
          }
      ]
    }
  ])

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
