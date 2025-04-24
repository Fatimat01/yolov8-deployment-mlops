data "aws_instances" "eks_nodes" {
  filter {
    name   = "tag:eks:nodegroup-name"
    values = ["yolov8-ng"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}


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
    ex-http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "80"
        protocol    = "HTTP"
        status_code = "HTTP_301"
      }

      rules = {
        ex-fixed-response = {
          priority = 3
          actions = [{
            type         = "fixed-response"
            content_type = "text/plain"
            status_code  = 200
            message_body = "This is a fixed response"
          }]
          conditions = [{
            http_header = {
              http_header_name = "Response"
              values           = ["*"]
            }
          }]
        }
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

resource "aws_lb_target_group_attachment" "eks_node_attachments" {
  for_each         = toset(data.aws_instances.eks_nodes.ids)
  target_group_arn = aws_lb_target_group.eks.arn
  target_id        = each.value
  port             = 30080

  depends_on = [module.alb, aws_lb_target_group.eks]
}