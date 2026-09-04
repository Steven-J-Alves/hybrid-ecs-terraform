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
  description = "Push nginx:alpine as :latest right after ECR creation so ECS services can start before CI has pushed real images. Requires docker + aws CLI on the runner (vps-native-runner has both)."
  type        = bool
  default     = true
}

variable "placeholder_image" {
  description = "Image to pull + tag + push as placeholder. Any small, always-available image works."
  type        = string
  default     = "nginx:alpine"
}
