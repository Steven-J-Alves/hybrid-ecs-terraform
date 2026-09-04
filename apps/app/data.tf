# ------- Account ID -------
data "aws_caller_identity" "id_current_account" {}

# ------- Cluster stack remote state — cluster ID, cluster name, private ALB HTTPS listener ARN -------
data "terraform_remote_state" "hybrid_apis" {
  backend = "s3"
  config = {
    bucket = "kriolu-kloud-terraform-tfstates"
    key    = "hybrid-cluster/${var.cluster_environment}/kriolu-kloud-hybrid-cluster-us-east-1.tfstate"
    region = "us-east-1"
  }
}

# -------
# ------- Common Data Soucers - Maverick -------
data "aws_acm_certificate" "acm_kriolu_kloud" {
  domain      = "*.kriolu-kloud.cv"
  statuses    = ["ISSUED", "PENDING_VALIDATION"]
  most_recent = true
}

data "aws_acm_certificate" "acm_kriolu_kloud_private" {
  domain      = "*.kriolu-kloud.cv"
  statuses    = ["ISSUED", "PENDING_VALIDATION"]
  most_recent = true
}

# data "aws_route53_zone" "zone" {
#   provider = aws.kriolu_kloud_account

#   name = "kriolu-kloud.cv."
# }

# data "aws_route53_zone" "private_zone" {
#   name = "crawler.com.br."
# }

# -------
# ------- VPC -------
data "aws_vpc" "crawler_vpc" {
  tags = {
    Owner = "KrioluKloud"
  }
}

# -------
# ------- Subnets -------
data "aws_subnets" "public_subnets" {
  filter {
    name   = "tag:Name"
    values = ["${var.subnet_public_filter}"]
  }
  filter {
    name   = "vpc-id"
    values = ["${data.aws_vpc.crawler_vpc.id}"]
  }
}
data "aws_subnets" "private_subnets" {
  filter {
    name   = "tag:Name"
    values = ["${var.subnet_private_filter}"]
  }
  filter {
    name   = "vpc-id"
    values = ["${data.aws_vpc.crawler_vpc.id}"]
  }
}

# -------
# ------- AZs -------
data "aws_availability_zones" "awz_zones" {}

# -------
# ------- Security Groups -------
data "aws_security_group" "sg_alb_public" {
  filter {
    name   = "tag:Name"
    values = ["${var.sg_alb_public_filter}"]
  }
  filter {
    name   = "vpc-id"
    values = ["${data.aws_vpc.crawler_vpc.id}"]
  }
}
data "aws_security_group" "sg_alb_private" {
  filter {
    name   = "tag:Name"
    values = ["${var.sg_alb_private_filter}"]
  }
  filter {
    name   = "vpc-id"
    values = ["${data.aws_vpc.crawler_vpc.id}"]
  }
}
data "aws_security_group" "sg_data_private" {
  filter {
    name   = "tag:Name"
    values = ["${var.sg_data_private_filter}"]
  }
  filter {
    name   = "vpc-id"
    values = ["${data.aws_vpc.crawler_vpc.id}"]
  }
}
data "aws_security_group" "sg_services_private" {
  filter {
    name   = "tag:Name"
    values = ["${var.sg_services_private_filter}"]
  }
  filter {
    name   = "vpc-id"
    values = ["${data.aws_vpc.crawler_vpc.id}"]
  }
}
data "aws_security_group" "sg_ssh_private" {
  filter {
    name   = "tag:Name"
    values = ["${var.sg_ssh_private_filter}"]
  }
  filter {
    name   = "vpc-id"
    values = ["${data.aws_vpc.crawler_vpc.id}"]
  }
}

# data "aws_security_group" "sg_ec2_private" {
#   filter {
#     name   = "tag:Name"
#     values = ["${var.sg_ec2_private_filter}"]
#   }
#   filter {
#     name   = "vpc-id"
#     values = ["${data.aws_vpc.crawler_vpc.id}"]
#   }
# }