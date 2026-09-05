variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment_name" {
  description = "Environment prefix (prod / homolog)"
  type        = string
  default     = "prod"
}

variable "rds_db_password" {
  description = "Master password for the RDS PostgreSQL instance. Pass via TF_VAR_rds_db_password or -var-file (never commit)."
  type        = string
  sensitive   = true
}
