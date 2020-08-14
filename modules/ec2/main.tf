
locals {
  instance-userdata = <<EOF
#!/bin/bash
sudo apt-get -y update
sudo apt-get -y install nginx
sudo service nginx start
echo "<h1>Deployed via Terraform</h1>" | sudo tee /var/www/html/index.html
EOF
}



data "aws_availability_zones" "all" {}


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
  launch_configuration = aws_launch_configuration.web_server.id
  availability_zones = [data.aws_availability_zones.all.names]
  min_size = 2
  max_size = 3
  load_balancers = aws_elb.example.name
  health_check_type = "ELB"
  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}


resource "aws_elb" "example" {
  name = "terraform-asg-example"
  security_groups = var.vpc_security_group_ids
  availability_zones = [data.aws_availability_zones.all.names]
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:80/"
  }
  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "80"
    instance_protocol = "http"
  }
}