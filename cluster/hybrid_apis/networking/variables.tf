variable "base_name" { type = string }
variable "vpc_cidr" { type = string }

variable "data_vpc" {}
variable "data_acm_certificate" {}
variable "data_acm_certificate_private" { }
variable "data_public_subnets" {}
variable "data_private_subnets" {}
variable "data_sg_alb_public" {}
variable "data_sg_alb_private" {}
