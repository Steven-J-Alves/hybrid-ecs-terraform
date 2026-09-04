terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "kriolu-kloud-terraform-tfstates"
    region         = "us-east-1"
    key            = "hybrid-network/homolog/kriolu-kloud-hybrid-vpc-us-east-1.tfstate"
    dynamodb_table = "kriolu-kloud-hybrid-network-terraform-lock"
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc_hybrid" {
  source = "../../vpc_hybrid"

  aws_region       = var.aws_region
  environment_name = var.environment_name
  service_name     = var.service_name
}
