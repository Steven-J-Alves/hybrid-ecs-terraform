terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "kriolu-kloud-terraform-tfstates"
    region         = "us-east-1"
    key            = "hybrid-apps/homolog/kriolu-kloud-hybrid-api-a-us-east-1.tfstate"
    dynamodb_table = "kriolu-kloud-hybrid-apps-terraform-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment_name
      Service     = var.tag_service
      Owner       = var.tag_owner
      CostCenter  = var.tag_costcenter
    }
  }
}

module "homolog_api_a" {
  source = "../../api-a"

  aws_region = var.aws_region

  environment_name    = var.environment_name
  gitlab_branch       = var.gitlab_branch
  cluster_environment = "homolog"

  vpc_cidr = var.vpc_cidr

  subnet_public_filter  = var.subnet_public_filter
  subnet_private_filter = var.subnet_private_filter
  iam_role_names        = var.iam_role_names
  app_host              = var.app_host
  app_api_host          = var.app_api_host
  rds_db_password       = var.rds_db_password
}

