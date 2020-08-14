
locals {
  instance-userdata = <<EOF
#!/bin/bash
sudo apt-get -y update
sudo apt-get -y install nginx
sudo service nginx start
echo "<h1>Deployed via Terraform</h1>" | sudo tee /var/www/html/index.html
EOF
}




resource "aws_launch_configuration" "web_server" {
  image_id               = var.ami_id
  instance_type          = var.instance_type
  security_groups        = var.vpc_security_group_ids
  key_name               = var.ec2_key
  user_data_base64        = "${base64encode(local.instance-userdata)}"
  lifecycle {
    create_before_destroy = true
  }
}



resource "aws_autoscaling_group" "web_asg" {
  name = "web-asg"

  vpc_zone_identifier       = var.lb_subnets
  launch_configuration      = aws_launch_configuration.web_server.name
  health_check_type         = "EC2"
  min_size                  = 2
  max_size                  = 3
  desired_capacity          = 2
  wait_for_capacity_timeout = 0

  lifecycle {
    create_before_destroy = true
  }

}


resource "aws_lb_target_group" "web_80" {
  name     = "web-tg-80"
  port     = "80"
  protocol = "HTTP"
  vpc_id   = "vpc-cb6d61b1"

  health_check {
    interval            = "30"
    protocol            = "HTTP"
    healthy_threshold   = "3"
    unhealthy_threshold = "3"
    port                = "80"
  }
}

resource "aws_autoscaling_attachment" "web_a80" {
  autoscaling_group_name = aws_autoscaling_group.web_asg.id
  alb_target_group_arn   = aws_lb_target_group.web_80.arn
}

resource "aws_lb" "web-lb" {
  name               = "web-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.lb_subnets
}

resource "aws_lb_listener" "web_l80" {
  load_balancer_arn = aws_lb.web-lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_80.arn
  }
}