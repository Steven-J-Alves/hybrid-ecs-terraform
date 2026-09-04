variable "name" {
  description = "The name of the deployed environment"
  type        = string
}

variable "vpc_zone_identifier" {
  description = "A list of VPC subnet IDs to launch resources in"
  type        = list(string)
}

variable "key_name" {
  description = "The name of the key pair to use for the instances"
  type        = string
}

variable "maximum_scaling_step_size" {
  description = "The maximum number of instances to add during a scaling action"
  type        = number
  default     = 2
}

variable "minimum_scaling_step_size" {
  description = "The minimum number of instances to remove during a scaling action"
  type        = number
  default     = 1
}

variable "target_capacity" {
  description = "The target number of instances to maintain in the Auto Scaling group"
  type        = number
  default     = 100
}

variable "managed_scaling_status" {
  description = <<EOT
    Specifies the status of managed scaling for the Auto Scaling group. 

    Valid values are:
    - "ENABLED": Managed scaling is enabled, allowing AWS to automatically adjust the capacity of the Auto Scaling group based on the target tracking policies.
    - "DISABLED": Managed scaling is disabled, which means the Auto Scaling group will not automatically adjust its capacity.

    Default is "ENABLED", enabling automated scaling for improved resource management and cost optimization.
  EOT
  type        = string
  default     = "ENABLED"
}


variable "image_id" {
  description = "The ID of the AMI to use for the instance"
  type        = string
  default     = "ami-0a04c4ef3341ccfd3"
}

# Define a variable for instance_type
variable "instance_type" {
  description = "The type of instance to use"
  type        = string
  default     = "t3.micro"
}

variable "security_groups" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "override_instance_types" {
  description = "A list of instance types to use for the mixed instances ASG"
  type        = list(string)
  default     = ["m6g.large", "c6g.xlarge", "c6g.large", "m6g.xlarge"]
}

variable "default_cooldown" {
  description = "The time in seconds after a scaling activity completes before another scaling activity can start."
  type        = number
  default     = 60
}

variable "health_check_grace_period" {
  description = "The amount of time in seconds that Auto Scaling waits after a new instance comes into service before checking its health status."
  type        = number
  default     = 15
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}


variable "container_insights" {
  description = "Enable or disable container insights"
  type        = string
  default     = "disabled"
}

variable "base_capacity" {
  description = "Base capacity for the default capacity provider strategy"
  type        = number
  default     = 1
}

variable "default_weight" {
  description = "Weight for the default capacity provider strategy"
  type        = number
  default     = 100
}

variable "termination_protection" {
  description = "Managed termination protection status"
  type        = string
  default     = "DISABLED"
}

variable "associate_public_ip" {
  description = "Whether to associate a public IP address with the instances"
  type        = bool
  default     = true
}

variable "min_size" {
  description = "Minimum number of instances in the Auto Scaling group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in the Auto Scaling group"
  type        = number
  default     = 1
}

variable "desired_capacity" {
  description = "Desired number of instances in the Auto Scaling group"
  type        = number
  default     = 1
}

variable "on_demand_base_capacity" {
  description = "On-demand base capacity in the mixed instances policy"
  type        = number
  default     = 0
}

variable "on_demand_percentage_above_base_capacity" {
  description = "On-demand percentage above base capacity"
  type        = number
  default     = 0
}

variable "spot_allocation_strategy" {
  description = "Spot allocation strategy for the mixed instances policy"
  type        = string
  default     = "price-capacity-optimized"
}

variable "scale_down_start_time" {
  description = "Start time for scaling down"
  type        = string
  default     = ""
}

variable "scale_down_recurrence" {
  description = "Recurrence rule for scaling down"
  type        = string
  default     = ""
}

variable "scale_up_start_time" {
  description = "Start time for scaling up"
  type        = string
  default     = ""
}

variable "scale_up_recurrence" {
  description = "Recurrence rule for scaling up"
  type        = string
  default     = ""
}

variable "node_role_name_prefix" {
  description = "Prefix for the ECS node role name"
  type        = string
  # default     = "${var.name}-node-role"
}

variable "ecs_node_policy_arn" {
  description = "ARN of the ECS node policy to attach"
  type        = string
  default     = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

variable "instance_profile_path" {
  description = "Path for the instance profile"
  type        = string
  default     = "/ecs/instance/"
}

variable "enable_scaling_schedule" {
  description = "Flag to enable scaling schedules for the ECS cluster"
  type        = bool
  default     = false # Default is false; set to true for clusters that need schedules
}
