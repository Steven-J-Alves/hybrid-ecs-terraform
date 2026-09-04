# Identity
variable "name" {
  description = "Short workload name (e.g. api, front, worker) — appended to app_name in all resource names"
  type        = string
}

variable "app_name" {
  description = "Application base name (e.g. p-app) — prefixed to all resource names"
  type        = string
}

variable "type" {
  description = "Workload type: 'http' provisions TG + listener rule; 'worker' omits all ALB resources"
  type        = string
  validation {
    condition     = contains(["http", "worker"], var.type)
    error_message = "type must be 'http' or 'worker'."
  }
}

# Container
variable "container_name" {
  description = "Container name inside the ECS task definition"
  type        = string
}

variable "cpu" {
  description = "Task CPU units (EC2 launch type)"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Task memory in MB"
  type        = number
  default     = 512
}

# HTTP-only: routing
variable "port" {
  description = "Container port — used for TG, SG ingress rule, and bridge port mapping (HTTP workloads)"
  type        = number
  default     = 80
}

variable "host_header" {
  description = "ALB host-header value for the private listener rule (HTTP workloads only)"
  type        = string
  default     = ""
}

variable "health_check_path" {
  description = "ALB health check path (HTTP workloads only)"
  type        = string
  default     = "/health"
}

variable "health_check_matcher" {
  description = "Health check expected HTTP response codes"
  type        = string
  default     = "200-499"
}

variable "alb_priority" {
  description = "ALB listener rule priority (null = AWS auto-assigns, avoids hardcoded values)"
  type        = number
  default     = null
}

variable "public_listener_arn" {
  description = "Public ALB HTTPS listener ARN — when set, creates a second TG + listener rule on the public ALB (HTTP workloads only)"
  type        = string
  default     = ""
}

variable "public_host_header" {
  description = "Host-header value for the public ALB listener rule (required when public_listener_arn is set)"
  type        = string
  default     = ""
}

# Scaling
variable "desired_count" {
  description = "Initial ECS desired task count"
  type        = number
  default     = 1
}

variable "min_capacity" {
  description = "Autoscaling minimum tasks"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Autoscaling maximum tasks"
  type        = number
  default     = 10
}

variable "cpu_target" {
  description = "Target CPU utilization % for autoscaling policy"
  type        = number
  default     = 80
}

variable "memory_target" {
  description = "Target memory utilization % for autoscaling policy"
  type        = number
  default     = 80
}

# Platform — passed from apps/app root module
variable "cluster_id" {
  description = "ECS cluster ID"
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnets" {
  description = "Private subnet IDs for ECS task placement"
  type        = list(string)
}

variable "allowed_cidrs" {
  description = "CIDR blocks allowed to reach the service (VPC CIDR + VPN)"
  type        = list(string)
}

variable "private_listener_arn" {
  description = "Private ALB HTTPS listener ARN (HTTP workloads only)"
  type        = string
  default     = ""
}

variable "private_http_listener_arn" {
  description = "Private ALB HTTP listener ARN — when set, creates a listener rule on port 80 (for internal Node.js service-to-service calls)"
  type        = string
  default     = ""
}

variable "execution_role_arn" {
  description = "ECS task execution role ARN"
  type        = string
}

variable "task_role_arn" {
  description = "ECS task role ARN"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment_vars" {
  description = "Environment variables to inject into the container as a map of name=value pairs"
  type        = map(string)
  default     = {}
}
