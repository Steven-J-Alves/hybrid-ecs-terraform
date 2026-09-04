variable "name" {
  description = "A name for the target group or ALB"
  type        = string
}

variable "target_group" {
  description = "The ARN of the created target group"
  type        = string
  default     = ""
}

variable "target_group_green" {
  description = "The ANR of the created target group"
  type        = string
  default     = ""
}

variable "create_alb" {
  description = "Set to true to create an ALB"
  type        = bool
  default     = false
}

variable "enable_http" {
  description = "Set to true to create a HTTP listener"
  type        = bool
  default     = false
}

variable "internal" {
  description = "Set to true to create internal ALB"
  type        = bool
  default     = false
}

variable "enable_http2" {
  description = "Set to true to enable HTTP2 protocol"
  type        = bool
  default     = true
}

variable "ssl_policy" {
  description = "Set to true to use SSL policy"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "Set to true to use SSL Certificate"
  type        = string
  default     = ""
}

variable "create_target_group" {
  description = "Set to true to create a Target Group"
  type        = bool
  default     = false
}

variable "subnets" {
  description = "Subnets IDs for ALB"
  type        = list(any)
  default     = []
}

variable "security_group" {
  description = "Security group ID for the ALB"
  type        = list(any)
  default     = []
}

variable "port" {
  description = "The port that the targer group will use"
  type        = number
  default     = 80
}

variable "protocol" {
  description = "The protocol that the target group will use"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID for the Target Group"
  type        = string
  default     = ""
}

variable "tg_type" {
  description = "Target Group Type (instance, IP, lambda)"
  type        = string
  default     = ""
}

variable "health_check_path" {
  description = "The path in which the ALB will send health checks"
  type        = string
  default     = ""
}

variable "health_check_port" {
  description = "The port to which the ALB will send health checks"
  type        = number
  default     = 80
}

variable "health_check_interval" {
  description = "The interval to which the ALB will send health checks"
  type        = number
  default     = 15
}

variable "health_check_timeout" {
  description = "The timeout to which the ALB will send health checks"
  type        = number
  default     = 10
}

variable "health_check_healthy_threshold" {
  description = "The healthy_threshold to which the ALB will send health checks"
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "The unhealthy_threshold to which the ALB will send health checks"
  type        = number
  default     = 3
}


variable "health_check_matcher" {
  description = "The matcher response status code"
  type        = string
  default     = "200"
}


