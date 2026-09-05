variable "name" {
  description = "The name of your ECR repository"
  type        = string
}

variable "aws_region" {
  description = "AWS region — used by aws ecr get-login-password"
  type        = string
  default     = "us-east-1"
}

variable "push_placeholder" {
  description = "Push nginx:alpine as :latest right after ECR creation. Requires docker + aws CLI on the runner. Set FALSE when terraform runs in the hashicorp/terraform container (no docker inside). Post-apply, run scripts/push-placeholders.sh."
  type        = bool
  default     = false
}

variable "placeholder_image" {
  description = "Image to pull + tag + push as placeholder. Any small, always-available image works."
  type        = string
  default     = "nginx:alpine"
}
