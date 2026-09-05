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
    key            = "hybrid-data/prod/kriolu-kloud-hybrid-data-us-east-1.tfstate"
    dynamodb_table = "kriolu-kloud-hybrid-data-terraform-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment_name
      Service     = "kriolu-kloud"
      Scope       = "hybrid-data"
      ManagedBy   = "terraform"
    }
  }
}

# ---------------------------------------------------------------------------
# Read network stack outputs (VPC id, subnets, SG)
# ---------------------------------------------------------------------------
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "kriolu-kloud-terraform-tfstates"
    key    = "hybrid-network/prod/kriolu-kloud-hybrid-vpc-us-east-1.tfstate"
    region = "us-east-1"
  }
}

locals {
  prefix        = "${substr(var.environment_name, 0, 1)}-hybrid-app"
  vpc_id        = data.terraform_remote_state.network.outputs.vpc_id
  private_sgids = [data.terraform_remote_state.network.outputs.sg_id_data_private]
  # Use database-subnets if they exist as a distinct output; otherwise fall back
  # to private subnets. The current vpc_hybrid module exposes them as `database_subnets`
  # in the origin but not re-exported yet; using private_subnets is safe (all in VPC).
  subnet_ids = data.terraform_remote_state.network.outputs.private_subnets
}

# ---------------------------------------------------------------------------
# RDS PostgreSQL — single instance, t4g.small, ~$25/month
# ---------------------------------------------------------------------------
module "postgres" {
  source = "../../../modules/rds"

  identifier          = "${local.prefix}-postgres"
  database            = "app"
  username            = "app_user"
  password            = var.rds_db_password
  engine              = "postgres"
  engine_version      = "16.4"
  instance_class      = "db.t4g.small"
  instance_port       = 5432
  allocated_storage   = "20"
  publicly_accessible = "false"
  vpc_id              = local.vpc_id
  subnets_id          = local.subnet_ids
  security_group_ids  = local.private_sgids
}

# ---------------------------------------------------------------------------
# ElastiCache Redis — single node, t4g.micro, ~$12/month
# ---------------------------------------------------------------------------
module "redis" {
  source = "../../../modules/elasticache"

  cluster_id         = "${local.prefix}-redis"
  engine             = "redis"
  node_type          = "cache.t4g.micro"
  num_cache_nodes    = "1"
  vpc_id             = local.vpc_id
  subnets_id         = local.subnet_ids
  security_group_ids = local.private_sgids
}
