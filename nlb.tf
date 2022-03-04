resource "aws_lb" "nlb" {
  name               = local.world
  internal           = false
  load_balancer_type = "network"
  subnets            = data.aws_subnet_ids.default.ids

  enable_deletion_protection = true
}

resource "aws_lb_target_group" "fivesix" {
  name_prefix = "vlbtg"
  port        = 2456
  protocol    = "UDP"
  vpc_id      = local.vpc_id

  health_check {
    port = "80"
  }

  stickiness {
    type    = "source_ip"
    enabled = false
  }
}

resource "aws_lb_target_group" "fiveseven" {
  name_prefix = "vlbtg"
  port        = 2457
  protocol    = "UDP"
  vpc_id      = local.vpc_id

  health_check {
    port = "80"
  }

  stickiness {
    type    = "source_ip"
    enabled = false
  }
}

resource "aws_lb_target_group" "fiveeight" {
  name_prefix = "vlbtg"
  port        = 2458
  protocol    = "UDP"
  vpc_id      = local.vpc_id

  health_check {
    port = "80"
  }

  stickiness {
    type    = "source_ip"
    enabled = false
  }
}

resource "aws_lb_listener" "fivesix" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "2456"
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fivesix.arn
  }
}

resource "aws_lb_listener" "fiveseven" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "2457"
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fiveseven.arn
  }
}

resource "aws_lb_listener" "fiveeight" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "2458"
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fiveeight.arn
  }
}
