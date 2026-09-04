variable "app_name" {
  description = "Application name (lowercase alphanumeric with hyphens)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*$", var.app_name))
    error_message = "app_name must be lowercase alphanumeric with hyphens."
  }
}

variable "environment_name" {
  description = "Environment name (prod or homolog) — used as resource name prefix"
  type        = string
  default     = "prod"
}

variable "cluster_environment" {
  description = "Cluster stack environment to read remote state from (prod or homolog)"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "port" {
  description = "Container port exposed by the application"
  type        = number
}

variable "domain" {
  description = "Hostname for ALB listener rule (e.g. myapp.kriolu-kloud.cv)"
  type        = string
}

variable "health_check_path" {
  description = "HTTP path for ALB health checks"
  type        = string
  default     = "/health"
}

variable "min_capacity" {
  description = "Minimum ECS task count"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum ECS task count"
  type        = number
  default     = 10
}

variable "cpu_target" {
  description = "Target CPU utilisation percentage for auto-scaling"
  type        = number
  default     = 80
}

variable "memory_target" {
  description = "Target memory utilisation percentage for auto-scaling"
  type        = number
  default     = 80
}

variable "subnet_private_filter" {
  description = "Name tag filter for private subnets"
  type        = string
  default     = "*kriolu-kloud-vpc-private*"
}

variable "kriolu_kloud_vpn" {
  description = "VPN/office IP CIDR allowed for ingress (defaults to VPC CIDR)"
  type        = string
  default     = "10.230.0.0/16"
}
