locals {
  is_http      = var.type == "http"
  is_public    = local.is_http && var.public_listener_arn != ""
  has_http_pvt = local.is_http && var.private_http_listener_arn != ""
  full_name    = "${var.app_name}-${var.name}"
}

# ECR repository — one per workload, named after the workload
module "ecr" {
  source = "../../ecr"
  name   = local.full_name
}

# Security group — HTTP workloads get ingress on var.port; workers get port 0 (all TCP from allowed CIDRs)
module "sg" {
  source              = "../../securitygroup"
  name                = "${local.full_name}-task-sg"
  description         = "Controls access to ${local.full_name} ECS task"
  vpc_id              = var.vpc_id
  ingress_port        = local.is_http ? var.port : 0
  cidr_blocks_ingress = var.allowed_cidrs
}

# Target group (HTTP only)
module "target_group" {
  count  = local.is_http ? 1 : 0
  source = "../../alb"

  create_target_group              = true
  name                             = "${local.full_name}-pvt"
  port                             = var.port
  protocol                         = "HTTP"
  vpc_id                           = var.vpc_id
  tg_type                          = "instance"
  health_check_path                = var.health_check_path
  health_check_healthy_threshold   = 2
  health_check_unhealthy_threshold = 2
  health_check_timeout             = 3
  health_check_interval            = 5
  health_check_matcher             = var.health_check_matcher
}

# Listener rule on the private ALB (HTTP only) — priority null = AWS auto-assigns (R3)
resource "aws_alb_listener_rule" "rule" {
  count        = local.is_http ? 1 : 0
  listener_arn = var.private_listener_arn
  priority     = var.alb_priority

  action {
    type             = "forward"
    target_group_arn = module.target_group[0].arn_tg
  }

  condition {
    host_header {
      values = [var.host_header]
    }
  }
}

# Listener rule on the private ALB port 80 (HTTP) — for Node.js service-to-service calls
resource "aws_alb_listener_rule" "rule_http" {
  count        = local.has_http_pvt ? 1 : 0
  listener_arn = var.private_http_listener_arn
  priority     = null

  action {
    type             = "forward"
    target_group_arn = module.target_group[0].arn_tg
  }

  condition {
    host_header {
      values = [var.host_header]
    }
  }
}

# Target group on the public ALB (optional — HTTP workloads with public_listener_arn set)
module "target_group_public" {
  count  = local.is_public ? 1 : 0
  source = "../../alb"

  create_target_group              = true
  name                             = "${local.full_name}-pub"
  port                             = var.port
  protocol                         = "HTTP"
  vpc_id                           = var.vpc_id
  tg_type                          = "instance"
  health_check_path                = var.health_check_path
  health_check_healthy_threshold   = 2
  health_check_unhealthy_threshold = 2
  health_check_timeout             = 3
  health_check_interval            = 5
  health_check_matcher             = var.health_check_matcher
}

# Listener rule on the public ALB — priority null = AWS auto-assigns (R3)
resource "aws_alb_listener_rule" "rule_public" {
  count        = local.is_public ? 1 : 0
  listener_arn = var.public_listener_arn
  priority     = null

  action {
    type             = "forward"
    target_group_arn = module.target_group_public[0].arn_tg
  }

  condition {
    host_header {
      values = [var.public_host_header]
    }
  }
}

# Task definition — bridge mode, dynamic host port (hostPort = 0)
module "task_definition" {
  source = "../task_definition"

  name               = "${local.full_name}-tf"
  network_mode       = "bridge"
  container_name     = var.container_name
  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.task_role_arn
  cpu                = tostring(var.cpu)
  memory             = tostring(var.memory)
  docker_repo        = module.ecr.ecr_repository_url
  region             = var.aws_region
  container_port     = local.is_http ? tostring(var.port) : ""
  port_mappings      = local.is_http ? jsonencode([{ containerPort = var.port, hostPort = 0 }]) : "[]"
  environment        = jsonencode([for k, v in var.environment_vars : { name = k, value = v }])
}

# ECS service
module "service" {
  source = "../service"

  name                              = local.full_name
  desired_tasks                     = tostring(var.desired_count)
  arn_security_group                = module.sg.sg_id
  ecs_cluster_id                    = var.cluster_id
  use_load_balancer                 = local.is_http
  arn_target_group                  = local.is_public ? [module.target_group[0].arn_tg, module.target_group_public[0].arn_tg] : local.is_http ? [module.target_group[0].arn_tg] : []
  arn_task_definition               = module.task_definition.arn_task_definition
  subnets_id                        = var.private_subnets
  container_port                    = local.is_public ? [var.port, var.port] : local.is_http ? [var.port] : []
  container_name                    = local.is_public ? [var.container_name, var.container_name] : local.is_http ? [var.container_name] : []
  health_check_grace_period_seconds = local.is_http ? 15 : null
}

# Autoscaling
module "autoscaling" {
  depends_on = [module.service]
  source     = "../autoscaling"

  name          = local.full_name
  cluster_name  = var.cluster_name
  min_capacity  = var.min_capacity
  max_capacity  = var.max_capacity
  cpu_target    = var.cpu_target
  memory_target = var.memory_target
}
