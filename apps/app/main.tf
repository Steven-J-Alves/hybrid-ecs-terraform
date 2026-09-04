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

module "rds_pg_cluster_app" {
  source = "../../modules/postgres"
  identifier                 = "${local.base_name}-pg"
  instance_identifier_suffix = "db"
  promotion_tier             = 1
  monitoring_interval        = 0
  database                   = "app"
  username                   = "app_user"
  engine                     = "aurora-postgresql"
  engine_version             = "17.7"
  aws_zones                  = slice(data.aws_availability_zones.awz_zones.names, 0, 3)
  instance_class             = "db.t4g.large"
  password                   = var.rds_db_password
  publicly_accessible        = false
  vpc_id                     = data.aws_vpc.crawler_vpc.id
  subnets_id                 = data.aws_subnets.private_subnets.ids
  security_group_ids         = [data.aws_security_group.sg_data_private.id]
}


