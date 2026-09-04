# ------- Service Name -------
variable "service_name" {
  description = "Project name"
  type        = string
  default     = "hybrid-apis"
}

variable "tag_service" {
  description = "Default tag: Service"
  type        = string
  default     = "Cluster-Main"
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

variable "ec2_key_name" {
  description = "EC2 SSH key pair name"
  type        = string
  default     = "kriolu-kloud-key"
}

variable "namespace_name" {
  description = "AWS Cloud Map private DNS namespace name for service discovery"
  type        = string
  default     = "kriolu-kloud.local"
}
