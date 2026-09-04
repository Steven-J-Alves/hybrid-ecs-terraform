
variable "engine" {
  description = "Engine for the SQL database"
  type        = string
  default     = "aurora-mysql"
}

variable "engine_version" {
  description = "Engine version for the SQL database"
  type        = string
  default     = "3.04.1"
}

variable "instance_class" {
  description = "Instance class for the SQL database"
  type        = string
  default     = "db.t4g.medium"
}

variable "instance_port" {
  description = "Instance Port for the SQL database"
  type        = number
  default     = 3306
}


variable "publicly_accessible" {
  description = "Publicly Accessible for the SQL database"
  type        = string
  default     = "false"
}

variable "allocated_storage" {
  description = "Allocated Storage for the SQL database"
  type        = string
  default     = "30"
}

variable "identifier" {
  description = "Identifier for the SQL database"
  type        = string
}

variable "database" {
  description = "Name for the SQL database"
  type        = string
}

variable "username" {
  description = "Username for the SQL database"
  type        = string
}

variable "password" {
  description = "Password for the SQL database"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where the security group will take place"
  type        = string
}

variable "subnets_id" {
  description = "Subnet ID to deploy RDS"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Set Security Groups IDS to RDS"
  type        = list(any)
}