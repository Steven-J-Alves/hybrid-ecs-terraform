resource "aws_ecs_service" "ecs_service" {
  name                              = var.name
  cluster                           = var.ecs_cluster_id
  task_definition                   = var.arn_task_definition
  desired_count                     = var.desired_tasks
  launch_type                       = var.launch_type
  health_check_grace_period_seconds = var.health_check_grace_period_seconds

  dynamic "load_balancer" {
    for_each = length(var.arn_target_group) > 0 ? zipmap(var.arn_target_group, var.container_port) : {}
    content {
      target_group_arn = load_balancer.key
      container_name   = var.container_name[0]
      container_port   = load_balancer.value
    }
  }

  enable_execute_command = true

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "instanceId"
  }

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  ordered_placement_strategy {
    type  = "binpack"
    field = "memory"
  }

  lifecycle {
    ignore_changes = [desired_count, task_definition, load_balancer, deployment_maximum_percent, tags]
  }

  propagate_tags = "SERVICE"
}
