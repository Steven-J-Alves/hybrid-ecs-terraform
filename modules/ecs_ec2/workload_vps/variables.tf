variable "app_name" {
  description = "Application base name — prefixed to all resource names (e.g. p-app)"
  type        = string
}

variable "name" {
  description = "Workload short name (e.g. api, front, worker) — appended to app_name"
  type        = string
}

variable "type" {
  description = "http | worker · http workloads get portMappings + Traefik dockerLabels; workers get neither"
  type        = string
  default     = "worker"
  validation {
    condition     = contains(["http", "worker"], var.type)
    error_message = "type must be 'http' or 'worker'."
  }
}

variable "container_name" {
  description = "Container name in the task definition"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on (HTTP workloads only — ignored for worker)"
  type        = number
  default     = 0
}

variable "cluster_id" {
  description = "ECS cluster ID (same cluster as AWS side — p-hybrid-apis)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for CloudWatch log group"
  type        = string
  default     = "us-east-1"
}

variable "ecr_repository_url" {
  description = "Full ECR repo URL (host/repo) — image is pulled as <url>:<image_tag> (default tag: latest)"
  type        = string
}

variable "image_tag" {
  description = "Image tag to run. Defaults to 'latest' — CI overwrites with git SHA"
  type        = string
  default     = "latest"
}

variable "cpu" {
  description = "Task CPU (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Task memory in MB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of task replicas on the VPS (WRR-balanced by Traefik if >1)"
  type        = number
  default     = 1
}

variable "execution_role_arn" {
  description = "IAM role for ECS agent to pull image + write logs"
  type        = string
}

variable "task_role_arn" {
  description = "IAM role assumed by the running container (defaults to execution_role if empty)"
  type        = string
  default     = ""
}

variable "environment_vars" {
  description = "Env vars injected into the container (map name → value)"
  type        = map(string)
  default     = {}
}

variable "extra_hosts" {
  description = "Static /etc/hosts entries inside container (map hostname → ipAddress). Use 'host-gateway' as ipAddress to point to the Docker bridge gateway (Traefik)."
  type        = map(string)
  default     = {}
}

variable "host_header" {
  description = "Hostname Traefik routes on (HTTP workloads only). If empty, no Traefik labels are added."
  type        = string
  default     = ""
}

variable "traefik_entrypoint" {
  description = "Traefik entrypoint the router binds to (web = :80)"
  type        = string
  default     = "web"
}

variable "extra_docker_labels" {
  description = "Additional dockerLabels to merge into the container definition"
  type        = map(string)
  default     = {}
}
