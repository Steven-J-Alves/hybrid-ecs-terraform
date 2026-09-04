variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment_name" {
  type    = string
  default = "prod"
}

variable "tag_service" {
  type    = string
  default = "App"
}

variable "tag_owner" {
  type    = string
  default = "KrioluKloud"
}

variable "tag_costcenter" {
  type    = string
  default = "KrioluKloud"
}

variable "gitlab_branch" {
  type    = string
  default = "main"
}

variable "vpc_cidr" {
  type    = string
  default = "10.230.0.0/16"
}

variable "subnet_public_filter" {
  type    = string
  default = "*kriolu-kloud-vpc-public*"
}

variable "subnet_private_filter" {
  type    = string
  default = "*kriolu-kloud-vpc-private*"
}

variable "rds_db_password" {
  description = "Aurora PostgreSQL password — pass via TF_VAR_rds_db_password"
  type        = string
  sensitive   = true
}
