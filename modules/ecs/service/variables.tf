variable "name" {
  description = "The name for the ecs service"
  type        = string
}

variable "desired_tasks" {
  description = "The minumum number of tasks to run in the service"
  type        = string
}

variable "arn_security_group" {
  description = "ARN of the security group for the tasks"
  type        = string
}

variable "ecs_cluster_id" {
  description = "The ECS cluster ID in which the resources will be created"
  type        = string
}

variable "use_load_balancer" {
  description = "Flag to active or inactive load balancer for ECS service"
  type        = bool
  default     = false
}

variable "arn_target_group" {
  description = "The ARN of the AWS Target Group to put the ECS task"
  type        = string
  default     = null
}

# variable "arn_target_group" {
#   description = "List of target group ARNs for the ECS service"
#   type        = list(string)
#   default     = []
# }

variable "arn_task_definition" {
  description = "The ARN of the Task Definition to use to deploy the tasks"
  type        = string
}

variable "subnets_id" {
  description = "Subnet ID in which ecs will deploy the tasks"
  type        = list(string)
}

variable "container_port" {
  description = "The port that the container will listen request"
  type        = string
  default     = ""
}

variable "container_name" {
  description = "The name of the container"
  type        = string
}