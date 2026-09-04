variable "service_name" { type = string }
variable "base_name" { type = string }
variable "environment_name"  { type = string }

variable "aws_region" { type = string }

variable "networking"  { }
variable "data_private_subnets"  { }

variable "sg_ssh" { }

variable "ec2_key_name" {}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}
