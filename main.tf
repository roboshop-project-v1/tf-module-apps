resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-sg"
  description = "${local.name_prefix}-sg"
  vpc_id      = var.vpc_id
  tags = var.tags
}


resource "aws_vpc_security_group_ingress_rule" "app" {
  security_group_id = aws_security_group.app.id

  cidr_ipv4   = var.ssh_ingress_cidr
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

resource "aws_security_group_rule" "app" {
  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  cidr_blocks       = var.sg_ingress_cidr
  security_group_id = aws_security_group.app.id
}


resource "aws_vpc_security_group_egress_rule" "rabbitmq" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports


}

resource "aws_launch_template" "apps" {
  name_prefix   = "${local.name_prefix}"
  image_id      = data.aws_ami.ami.id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.app.id]
  user_data = base64encode(templatefile("${path.module}/userdata.sh",
  {
    component=var.component
  }))
}

resource "aws_autoscaling_group" "apps" {
  vpc_zone_identifier = var.subnet_ids
  desired_capacity   = var.desired_capacity
  max_size           = var.max_size
  min_size           = var.min_size
  target_group_arns = [aws_lb_target_group.apps.arn]

  launch_template {
    id      = aws_launch_template.apps.id
    version = "$Latest"
  }
}

resource "aws_route53_record" "apps" {
  zone_id = var.zone_id
  name    = var.component == "frontend" ? var.env:"${var.component}-${var.env}"
  type    = "CNAME"
  ttl     = 30
  records = [var.component == "frontend"? var.public_alb_name : var.private_alb_name]
}

resource "aws_lb_target_group" "apps" {
  name     = local.name_prefix
  port     = var.port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}



resource "aws_lb_listener_rule" "apps" {
  listener_arn = var.private_listener
  priority     = var.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.apps.arn
  }


  condition {
    host_header {
      values = [var.component == "frontend"? "${var.env}.jdevops.online":"${var.component}-${var.env}.jdevops.online"]
    }
  }
}
resource "aws_lb_target_group" "public" {
  count = var.component == "frontend"? 1:0
  name     = "${local.name_prefix}-public"
  port     = var.port
  target_type = "ip"
  protocol = "HTTP"
  vpc_id   = var.default_vpc_id
}

resource "aws_lb_target_group_attachment" "public" {
  count = var.component == "frontend"? length(var.subnet_ids):0
  target_group_arn = aws_lb_target_group.public[0].arn
  target_id        = element(tolist(data.dns_a_record_set.private_alb.addrs),count.index)
  port             = 80
  availability_zone = "all"
}


resource "aws_lb_listener_rule" "public" {
  count = var.component == "frontend" ? 1 : 0
  listener_arn = var.public_listener
  priority     = var.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public[0].arn
  }

  condition {
    host_header {
      values = ["${var.env}.jdevops.online"]
    }
  }
}