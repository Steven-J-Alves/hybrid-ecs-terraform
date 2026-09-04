resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                   = var.name
  network_mode             = var.network_mode
  requires_compatibilities = ["EC2"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = length(var.task_role_arn) > 0 ? var.task_role_arn : var.execution_role_arn

  container_definitions = <<DEFINITION
    [
      {
        "logConfiguration": {
          "logDriver": "awslogs",
          "secretOptions": null,
          "options": {
            "awslogs-group": "/ecs/task-definition-${var.name}",
            "awslogs-region": "${var.region}",
            "awslogs-stream-prefix": "ecs"
          }
        },
        "cpu": 0,
        "image": "${var.docker_repo}",
        "name": "${var.container_name}",
        "networkMode": "${var.network_mode}",
        "portMappings": ${var.port_mappings},
        "environment": ${var.environment},
        "environmentFiles": ${var.environmentFiles},
        "linuxParameters": ${jsonencode(var.linuxParameters)},
        "command": ${jsonencode(jsondecode(var.command))}
      }
    ]
  DEFINITION

  lifecycle {
    ignore_changes = [container_definitions, tags]
  }
}

resource "aws_cloudwatch_log_group" "task_log_group" {
  name              = "/ecs/task-definition-${var.name}"
  retention_in_days = 1
}
