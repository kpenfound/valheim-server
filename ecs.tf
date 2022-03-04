resource "aws_autoscaling_group" "ecs" {
  name                 = local.world
  min_size             = 0
  max_size             = 1
  desired_capacity     = 1
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

resource "aws_ecs_cluster" "cluster" {
  name = local.world
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
        "Sid"    = "",
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
    "Statement" : [
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
