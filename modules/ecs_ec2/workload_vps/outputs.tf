output "service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.vps.name
}

output "task_definition_arn" {
  description = "Task definition ARN (family:revision)"
  value       = aws_ecs_task_definition.vps.arn
}

output "task_family" {
  description = "Task definition family"
  value       = aws_ecs_task_definition.vps.family
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.vps.name
}
