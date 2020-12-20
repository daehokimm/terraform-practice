provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_launch_configuration" "example" {
  image_id        = "ami-007b7745d0725de95"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instance.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "instance" {
  name        = "terraform-practice-instance"
  description = "daehokimm-terraform-practice"

  ingress {
    security_groups = [aws_security_group.elb.id]
    protocol        = "tcp"
    from_port       = var.server_port
    to_port         = var.server_port
  }

  tags = {
    "Name" = "daehokimm-terraform-practice-instance"
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.id
  availability_zones   = data.aws_availability_zones.all.names
  min_size             = 2
  max_size             = 3

  load_balancers    = [aws_elb.example.name]
  health_check_type = "ELB"

  tag {
    key                 = "Name"
    value               = "terraform-asg-exampe"
    propagate_at_launch = true
  }
}

resource "aws_elb" "example" {
  name               = "terraform-elb-example"
  availability_zones = data.aws_availability_zones.all.names
  security_groups    = [aws_security_group.elb.id]

  listener {
    lb_port           = 80
    lb_protocol       = "HTTP"
    instance_port     = var.server_port
    instance_protocol = "HTTP"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 3
    interval            = 30
    target              = "HTTP:${var.server_port}/"
  }
}

resource "aws_security_group" "elb" {
  name = "terraform-example-elb"

  ingress {
    cidr_blocks = [var.elb_cidr_blocks]
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
}

data "aws_availability_zones" "all" {}

variable "server_port" {
  description = "http server port"
  default     = 8080
}

variable "elb_cidr_blocks" {}

output "elb_dns_name" {
  value = aws_elb.example.dns_name
}
