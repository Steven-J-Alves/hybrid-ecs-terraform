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
    devops        = "h-app-tf-devops-role"
    ecs           = "h-app-tf-ecs-task-execution-role"
    ecs_task_role = "h-app-tf-ecs-task-role"
  }
}

variable "app_host" {
  type    = string
  default = "app-h.kriolu-kloud.cv"
}

variable "app_api_host" {
  type    = string
  default = "app-api-h.kriolu-kloud.cv"
}

variable "rds_db_password" {
  description = "Aurora PostgreSQL password — pass via TF_VAR_rds_db_password"
  type        = string
  sensitive   = true
}
