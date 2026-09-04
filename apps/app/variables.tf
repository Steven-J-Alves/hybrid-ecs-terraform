# ------- Service Name -------
variable "service_name" {
  description = "Project name"
  type        = string
  default     = "app"
}

variable "tag_service" {
  description = "Default tag: Service"
  type        = string
  default     = "App"
}

variable "tag_owner" {
  description = "Default tag: Owner"
  type        = string
  default     = "KrioluKloud"
}

variable "tag_costcenter" {
  description = "Default tag: CostCenter"
  type        = string
  default     = "KrioluKloud"
}

# ------- AWS Access -------
variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "us-east-1"
}

# ------- AWS Resources -------
variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
  default     = "10.230.0.0/16"
}

variable "subnet_public_filter" {
  description = "Name tag filter for public subnets (supports wildcards)"
  type        = string
  default     = "*kriolu-kloud-vpc-public*"
}

variable "subnet_private_filter" {
  description = "Name tag filter for private subnets (supports wildcards)"
  type        = string
  default     = "*kriolu-kloud-vpc-private*"
}

variable "sg_alb_public_filter" {
  description = "Name tag filter for the public ALB security group"
  type        = string
  default     = "alb-public-sg"
}

variable "sg_alb_private_filter" {
  description = "Name tag filter for the private ALB security group"
  type        = string
  default     = "alb-private-sg"
}

variable "sg_data_private_filter" {
  description = "Name tag filter for the data-layer security group"
  type        = string
  default     = "data-private-sg"
}

variable "sg_services_private_filter" {
  description = "Name tag filter for the services security group"
  type        = string
  default     = "services-private-sg"
}

variable "sg_ssh_private_filter" {
  description = "Name tag filter for the SSH security group"
  type        = string
  default     = "ssh-private-sg"
}

variable "iam_role_names" {
  description = "IAM role name for each service"
  type        = map(string)
  default = {
    devops        = "app-tf-devops-role"
    ecs           = "app-tf-ecs-task-execution-role"
    ecs_task_role = "app-tf-ecs-task-role"
  }
}

variable "kriolu_kloud_vpn" {
  description = "VPN/office IP CIDR allowed for ingress to service security groups"
  type        = string
  default     = "10.230.0.0/16" # defaults to VPC CIDR; override with actual VPN IP via TF_VAR_kriolu_kloud_vpn
}

# ------- Environment -------
variable "environment_name" {
  description = "Environment name (used in resource name prefixes)"
  type        = string
  default     = "prod"

  validation {
    condition     = length(var.environment_name) < 23
    error_message = "Due the this variable is used for concatenation of names of other resources, the value must have less than 23 characters."
  }
}

variable "gitlab_branch" {
  description = "GitLab branch that triggered the deployment"
  type        = string
  default     = "main"
}

variable "gitlab_url" {
  description = "GitLab instance URL"
  type        = string
  default     = "https://gitlab.kriolu-kloud.cv"
}

# ------- Services -------
variable "rds_db_password" {
  description = "Password for the Aurora PostgreSQL database — pass via TF_VAR_rds_db_password in CI"
  type        = string
  sensitive   = true
}

variable "cluster_environment" {
  description = "Environment name of the cluster stack to read remote state from (prod or homolog)"
  type        = string
  default     = "prod"
}

variable "port_api_app" {
  description = "Port exposed by the app-api container"
  type        = number
  default     = 4004
}

variable "container_name" {
  description = "Container name for each ECS service"
  type        = map(string)
  default = {
    app_api        = "container-app-api"
    app_worker     = "container-app-worker"
    app_scheduler  = "container-app-scheduler"
    app_manager    = "container-app-manager"
    app_front      = "container-app-front"
  }
}

variable "port_front_app" {
  description = "Port exposed by the nginx serving app-front"
  type        = number
  default     = 80
}

variable "app_host" {
  description = "Public hostname for the app frontend (used in Route53 + ALB listener rules)"
  type        = string
  default     = "app.kriolu-kloud.cv"
}

variable "app_api_host" {
  description = "Private hostname for the app API (used in Route53 + ALB listener rules + API_URL env var)"
  type        = string
  default     = "app-api.kriolu-kloud.cv"
}

