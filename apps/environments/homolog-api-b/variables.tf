variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment_name" {
  type    = string
  default = "homolog"
}

variable "tag_service" {
  type    = string
  default = "App2"
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
  default = "homolog"
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

variable "iam_role_names" {
  type = map(string)
  default = {
    devops        = "h-app2-tf-devops-role"
    ecs           = "h-app2-tf-ecs-task-execution-role"
    ecs_task_role = "h-app2-tf-ecs-task-role"
  }
}

variable "app2_host" {
  type    = string
  default = "app2-h.kriolu-kloud.cv"
}

variable "app2_api_host" {
  type    = string
  default = "app2-api-h.kriolu-kloud.cv"
}

variable "rds_db_password" {
  description = "Aurora PostgreSQL password — pass via TF_VAR_rds_db_password"
  type        = string
  sensitive   = true
}
