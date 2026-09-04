output "ecr_repository_url" {
  value       = module.ecr.ecr_repository_url
  description = "ECR repository URL — use this when pushing container images in CI"
}

output "security_group_id" {
  value       = module.sg.sg_id
  description = "Security group ID of the ECS task"
}

output "target_group_arn" {
  value       = local.is_http ? module.target_group[0].arn_tg : ""
  description = "Target group ARN (empty string for worker workloads)"
}
