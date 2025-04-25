module "alb" {
  depends_on                 = [module.eks, module.vpc]
  source                     = "terraform-aws-modules/alb/aws"
  name                       = "yolov8-alb"
  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.vpc.public_subnets
  enable_deletion_protection = false

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      fixed_response = {
        content_type = "text/plain"
        message_body = "Fixed message"
        status_code  = "200"
      }
    }
  }

  tags = {
    Project = "YOLOv8-EKS"
  }
}


resource "aws_lb_target_group" "eks" {
  name        = "yolov8-tg"
  protocol    = "HTTP"
  port        = 30080
  target_type = "instance"
  vpc_id      = module.vpc.vpc_id
}

data "aws_instances" "eks_nodes" {
  filter {
    name   = "tag:Name"
    values = ["yolov8-ng"]
  }

}

resource "aws_lb_target_group_attachment" "eks_node_attachments" {
  count =    length(data.aws_instances.eks_nodes.ids)
  target_group_arn = aws_lb_target_group.eks.arn
  target_id        = count.index
  port             = 30080

  depends_on = [module.alb, aws_lb_target_group.eks]
}