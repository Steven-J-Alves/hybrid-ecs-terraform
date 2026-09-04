# Input Variables

# ------- Environment -------
variable "environment_name" {
  description = "The name of your environment"
  type        = string
  default     = "prod"

  validation {
    condition     = length(var.environment_name) < 23
    error_message = "Due the this variable is used for concatenation of names of other resources, the value must have less than 23 characters."
  }
}

# ------- AWS Access -------
variable "aws_region" {
  description = "The AWS Region in which you want to deploy the resources"
  type        = string
}

# variable "aws_profile" {
#   description = "The profile name that you have configured in the file .aws/credentials"
#   type        = string
# }

# ------- Service Info -------
variable "service_name" {
  description = "Project Name"
  type        = string
  default     = "kriolu-kloud"
}

variable "tag_service" {
  description = "Default_Tag Service"
  type        = string
  default     = "kriolu-kloud"
}

variable "tag_owner" {
  description = "Default_Tag Owner"
  type        = string
  default     = "KrioluKloud"
}

variable "tag_costcenter" {
  description = "Default_Tag CostCenter"
  type        = string
  default     = "Devops"
}

