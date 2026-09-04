
variable "engine" {
  description = "Engine for the SQL database"
  type        = string
  default     = "aurora-postgresql"
}

variable "engine_version" {
  description = "Engine version for the SQL database"
  type        = string
  default     = "17.4"
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
  default     = "20"
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

variable "aws_zones" {
  description = "Set AWS AZs"
  type        = list(string)
}

# 1 for only write instance and 2 for write and reader instances
variable "reader_instance" {
  description = "Set an instance for reader"
  type        = number
  default     = 1
}

variable "multi_az" { default = false }

variable "read_replica_count" { default = 0 }

variable "deletion_protection" { default = false }

variable "instance_identifier_suffix" {
  description = "Suffix appended to var.identifier to form the cluster instance identifier. Default keeps backwards-compat (`instance-0`)."
  type        = string
  default     = "instance-0"
}

variable "promotion_tier" {
  description = "Failover Priority for the cluster instance (lower = higher priority)."
  type        = number
  default     = 0
}

variable "monitoring_interval" {
  description = "Seconds between Enhanced Monitoring metrics collection. 0 disables."
  type        = number
  default     = 0
}
