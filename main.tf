# provider "aws" {
#   region  = var.aws_region
#   version = "~> 2.0"
#   assume_role {
#     role_arn     = var.account_role_arn
#     session_name = "ec2"
#   }
# }


provider "aws" {
  version = "~> 2.0"
  region  = var.aws_region
}

backend "s3" {}
module "ec2" {
    source      = "./modules/ec2"
    ami_id = var.ami_id
    instance_type = var.instance_type
    ec2_key = var.ec2_key
    subnet_id = var.subnet_id
    security_group_ids = var.security_group_ids
}
