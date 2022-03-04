resource "aws_ecs_service" "dummy" {
  name_prefix     = "dummy"
  cluster         = aws_ecs_cluster.cluster.name
  task_definition = aws_ecs_task_definition.dummy.arn
  desired_count   = 0

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  launch_type = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.fiveseven.arn
    container_name   = "dummy"
    container_port   = 2457
  }
}

resource "aws_ecr_repository" "dummy" {
  name = "dummy-${local.world}"
}

resource "aws_ecr_repository_policy" "foopolicy" {
  repository = aws_ecr_repository.dummy.name

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "new policy",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:DeleteRepository",
                "ecr:BatchDeleteImage",
                "ecr:SetRepositoryPolicy",
                "ecr:DeleteRepositoryPolicy"
            ]
        }
    ]
}
EOF
}

resource "aws_ecs_task_definition" "dummy" {
  family                   = "dummy"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  container_definitions    = <<TASK_DEFINITION
[
  {
    "name": "dummy",
    "image": "${aws_ecr_repository.dummy.name}/dummy:latest",
    "cpu": 256,
    "memory": 512,
    "essential": true
  }
]
TASK_DEFINITION

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}
