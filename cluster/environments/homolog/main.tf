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
    key            = "hybrid-cluster/homolog/kriolu-kloud-hybrid-cluster-us-east-1.tfstate"
    dynamodb_table = "kriolu-kloud-hybrid-cluster-terraform-lock"
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

module "homolog_hybrid_apis" {
  source = "../../hybrid_apis"

  aws_region = var.aws_region

  environment_name = var.environment_name

  vpc_cidr = var.vpc_cidr

  subnet_public_filter  = var.subnet_public_filter
  subnet_private_filter = var.subnet_private_filter

  namespace_name = var.namespace_name
}

