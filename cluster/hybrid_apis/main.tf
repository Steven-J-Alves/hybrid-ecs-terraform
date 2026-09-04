# ------- Terraform -------
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ------- ALB + Security/Target Groups -------
module "networking" {
  source    = "./networking"
  base_name = local.base_name

  vpc_cidr = data.aws_vpc.kriolu_kloud_vpc.cidr_block

  data_vpc             = data.aws_vpc.kriolu_kloud_vpc
  data_acm_certificate = data.aws_acm_certificate.acm_kriolu_kloud
  data_acm_certificate_private = data.aws_acm_certificate.acm_kriolu_kloud_private

  data_public_subnets  = data.aws_subnets.public_subnets
  data_private_subnets = data.aws_subnets.private_subnets
  data_sg_alb_public   = data.aws_security_group.sg_alb_public
  data_sg_alb_private  = data.aws_security_group.sg_alb_private
}

module "ecs_clusters" {
  source = "./ecs"
  service_name = var.service_name
  base_name = local.base_name
  environment_name = var.environment_name

  aws_region = var.aws_region

  networking = module.networking
  data_private_subnets = data.aws_subnets.private_subnets

  sg_ssh = data.aws_security_group.sg_ssh_private

  ec2_key_name = var.ec2_key_name
  tags = local.common_tags
}

