# ------- Account ID -------
data "aws_caller_identity" "id_current_account" {}

# ------- ACM Certificates -------
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

# ------- VPC -------
data "aws_vpc" "kriolu_kloud_vpc" {
  tags = {
    Owner = "KrioluKloud"
  }
}

# ------- Subnets -------
data "aws_subnets" "public_subnets" {
  filter {
    name   = "tag:Name"
    values = ["${var.subnet_public_filter}"]
  }
  filter {
    name   = "vpc-id"
    values = ["${data.aws_vpc.kriolu_kloud_vpc.id}"]
  }
}
data "aws_subnets" "private_subnets" {
  filter {
    name   = "tag:Name"
    values = ["${var.subnet_private_filter}"]
  }
  filter {
    name   = "vpc-id"
    values = ["${data.aws_vpc.kriolu_kloud_vpc.id}"]
  }
}

# ------- AZs -------
data "aws_availability_zones" "awz_zones" {}

# ------- Security Groups -------
data "aws_security_group" "sg_alb_public" {
  filter {
    name   = "tag:Name"
    values = ["${var.sg_alb_public_filter}"]
  }
  filter {
    name   = "vpc-id"
    values = ["${data.aws_vpc.kriolu_kloud_vpc.id}"]
  }
}
data "aws_security_group" "sg_alb_private" {
  filter {
    name   = "tag:Name"
    values = ["${var.sg_alb_private_filter}"]
  }
  filter {
    name   = "vpc-id"
    values = ["${data.aws_vpc.kriolu_kloud_vpc.id}"]
  }
}
data "aws_security_group" "sg_data_private" {
  filter {
    name   = "tag:Name"
    values = ["${var.sg_data_private_filter}"]
  }
  filter {
    name   = "vpc-id"
    values = ["${data.aws_vpc.kriolu_kloud_vpc.id}"]
  }
}
data "aws_security_group" "sg_services_private" {
  filter {
    name   = "tag:Name"
    values = ["${var.sg_services_private_filter}"]
  }
  filter {
    name   = "vpc-id"
    values = ["${data.aws_vpc.kriolu_kloud_vpc.id}"]
  }
}
data "aws_security_group" "sg_ssh_private" {
  filter {
    name   = "tag:Name"
    values = ["${var.sg_ssh_private_filter}"]
  }
  filter {
    name   = "vpc-id"
    values = ["${data.aws_vpc.kriolu_kloud_vpc.id}"]
  }
}
