resource "aws_instance" "ec2" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name = var.ec2_key
  subnet_id = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids
  user_data = << EOF
		      #! /bin/bash
          sudo apt-get -y update
          sudo apt-get -y install nginx
          sudo service nginx start
          echo "<h1>Deployed via Terraform</h1>" >> sudo tee /var/www/html/index.html
  EOF
}

resource "aws_elb" "web" {
  name = "webserver"

  subnets         = var.lb_subnets
  security_groups = var.vpc_security_group_ids
  instances       = [aws_instance.ec2.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}
