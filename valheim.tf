
locals {
  script_backup = base64encode(templatefile("${path.module}/scripts/backup.sh.tftpl",
    {
      bucket_id = aws_s3_bucket.backups.id
  }))
  script_setup_healthcheck = file("${path.module}/scripts/setup_healthcheck.sh")
}

resource "aws_autoscaling_group" "valheim" {
  name                 = local.world
  min_size             = 0
  max_size             = 1
  desired_capacity     = 1
  vpc_zone_identifier  = data.aws_subnets.default.ids
  launch_configuration = aws_launch_configuration.valheim.name

  target_group_arns = [
    aws_lb_target_group.fivesix.arn,
    aws_lb_target_group.fiveseven.arn,
    aws_lb_target_group.fiveeight.arn
  ]

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_launch_configuration" "valheim" {
  name_prefix          = local.world
  image_id             = var.ecs_ami
  instance_type        = var.instance_type
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.ecs_instance.name

  user_data = <<EOF
#!/bin/bash
echo ECS_CLUSTER=${local.world} >> /etc/ecs/ecs.config
yum install -y awscli
${local.script_setup_healthcheck}
echo ${local.script_backup} | base64 --decode > /home/ec2-user/backup.sh
/usr/bin/aws s3 sync s3://${aws_s3_bucket.backups.id}/ /home/ec2-user/valheim/
(crontab -l 2>/dev/null; echo "${var.world_backup_schedule} sh /home/ec2-user/backup.sh") | crontab - 
(crontab -l 2>/dev/null; echo "* * * * * sh /home/ec2-user/idlecounter.sh") | crontab - 
EOF

  security_groups = [aws_security_group.cluster_instance.id]

  lifecycle {
    create_before_destroy = true
  }
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

resource "aws_ecs_service" "valheim" {
  name            = local.world
  cluster         = aws_ecs_cluster.cluster.name
  task_definition = aws_ecs_task_definition.valheim.arn
  desired_count   = 1

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }
}

resource "aws_ecs_task_definition" "valheim" {
  family = local.world

  container_definitions = jsonencode([
    {
      "cpu" = var.task_cpu,
      "environment" = [
        {
          "name"  = "NAME",
          "value" = var.world_name
        },
        {
          "name"  = "WORLD",
          "value" = var.world_name
        },
        {
          "name"  = "PASSWORD",
          "value" = var.world_password
        },
        {
          "name"  = "PUBLIC",
          "value" = var.world_public
        },
        {
          "name"  = "TZ",
          "value" = var.world_tz
        },
        {
          "name"  = "AUTO_BACKUP",
          "value" = var.world_backup
        },
        {
          "name"  = "AUTO_BACKUP_SCHEDULE",
          "value" = var.world_backup_schedule
        },
        {
          "name"  = "AUTO_BACKUP_REMOVE_OLD",
          "value" = var.world_backup_remove_old
        },
        {
          "name"  = "AUTO_BACKUP_DAYS_TO_LIVE",
          "value" = var.world_backup_days_to_live
        },
        {
          "name"  = "AUTO_UPDATE",
          "value" = var.world_update
        },
        {
          "name"  = "AUTO_UPDATE_SCHEDULE",
          "value" = var.world_update_schedule
        },
        {
          "name"  = "AUTO_BACKUP_ON_UPDATE",
          "value" = "1"
        },
        {
          "name"  = "AUTO_BACKUP_ON_SHUTDOWN",
          "value" = "1"
        },
        {
          "name"  = "UPDATE_ON_STARTUP",
          "value" = "1"
        }
      ],
      "essential"         = true,
      "image"             = "${var.docker_image}:${var.docker_image_version}",
      "memoryReservation" = var.task_memory,
      "name"              = local.world,
      "portMappings" = [
        {
          "containerPort" = 2456,
          "hostPort"      = 2456,
          "protocol"      = "udp"
        },
        {
          "containerPort" = 2457,
          "hostPort"      = 2457,
          "protocol"      = "udp"
        },
        {
          "containerPort" = 2458,
          "hostPort"      = 2458,
          "protocol"      = "udp"
        }
      ],
      "mountPoints" = [
        {
          "containerPath" = "/home/steam/.config/unity3d/IronGate/Valheim",
          "sourceVolume"  = "saves"
        },
        {
          "containerPath" = "/home/steam/valheim",
          "sourceVolume"  = "server"
        },
        {
          "containerPath" = "/home/steam/backups",
          "sourceVolume"  = "backups"
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
