resource "aws_ecs_cluster" "dummy" {
  name = "dummy-${local.world}"
}

resource "aws_ecs_service" "dummy" {
  name            = "dummy-${local.world}"
  cluster         = aws_ecs_cluster.dummy.name
  task_definition = aws_ecs_task_definition.dummy.arn
  desired_count   = 0

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  load_balancer {
    target_group_arn = aws_lb_target_group.fiveseven.arn
    container_name   = "dummy"
    container_port   = 2457
  }
}

resource "aws_ecs_task_definition" "dummy" {
  family       = "dummy-${local.world}"
  network_mode = "bridge"
  cpu          = 256
  memory       = 256

  container_definitions = jsonencode([
    {
      "name"      = "dummy",
      "image"     = "kylepenfound/valheim-dummy:latest",
      "cpu"       = 256,
      "memory"    = 256,
      "essential" = true,
      "environment" = [
        {
          "name"  = "VALHEIM_SERVICE",
          "value" = local.world
        },
        {
          "name"  = "DUMMY_SERVICE",
          "value" = "dummy-${local.world}"
        },
        {
          "name"  = "VALHEIM_CLUSTER",
          "value" = local.world
        },
        {
          "name"  = "DUMMY_CLUSTER",
          "value" = "dummy-${local.world}"
        },
        {
          "name"  = "VALHEIM_ASG",
          "value" = local.world
        },
        {
          "name"  = "DUMMY_ASG",
          "value" = "dummy-${local.world}"
        },
        {
          "name"  = "AWS_REGION",
          "value" = var.region
        }
      ],
      "portMappings" = [
        {
          "containerPort" = 2457,
          "hostPort"      = 2457,
          "protocol"      = "udp"
        }
      ]
    }
  ])
}

resource "aws_autoscaling_group" "dummy" {
  name                 = "dummy-${local.world}"
  min_size             = 0
  max_size             = 1
  desired_capacity     = 0
  vpc_zone_identifier  = data.aws_subnets.default.ids
  launch_configuration = aws_launch_configuration.dummy.name

  target_group_arns = [
    aws_lb_target_group.fivesix.arn,
    aws_lb_target_group.fiveseven.arn,
    aws_lb_target_group.fiveeight.arn
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "dummy" {
  name_prefix          = "dummy"
  image_id             = var.ecs_ami
  instance_type        = var.dummy_instance_type
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.ecs_instance.name

  user_data = <<EOF
#!/bin/bash
echo ECS_CLUSTER=dummy-${local.world} >> /etc/ecs/ecs.config
yum install -y awscli
${local.script_setup_healthcheck}
EOF

  security_groups = [aws_security_group.cluster_instance.id]

  lifecycle {
    create_before_destroy = true
  }
}
