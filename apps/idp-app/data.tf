data "aws_caller_identity" "current" {}

data "terraform_remote_state" "hybrid_apis" {
  backend = "s3"
  config = {
    bucket = "kriolu-kloud-terraform-tfstates"
    key    = "hybrid-cluster/${var.cluster_environment}/kriolu-kloud-hybrid-cluster-us-east-1.tfstate"
    region = "us-east-1"
  }
}

data "aws_vpc" "main" {
  tags = {
    Owner = "KrioluKloud"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "tag:Name"
    values = [var.subnet_private_filter]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}
