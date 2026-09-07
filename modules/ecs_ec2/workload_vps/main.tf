# workload_vps — one ECS service that runs on the VPS via ECS Anywhere.
#
# Differences vs `workload/` (AWS side):
#   - requires_compatibilities = ["EXTERNAL"]
#   - launch_type              = "EXTERNAL"
#   - No security group        (VPS network is Docker bridge, no AWS SG)
#   - No target group          (Traefik on VPS discovers via dockerLabels)
#   - No autoscaling           (ECS Anywhere doesn't support app-autoscaling)
#   - dockerLabels + extraHosts (Traefik routing + inter-API host-gateway trick)

locals {
  full_name    = "${var.app_name}-${var.name}-vps"
  log_group    = "/ecs/${local.full_name}"
  is_http      = var.type == "http"
  router_alias = "${var.app_name}-${var.name}" # short alias for Traefik router/service names

  # Traefik router rule: primary host_header + any alternates (Host(a) || Host(b) || ...)
  # Enables direct DNS names (e.g. direct.kriolu-kloud.cv → VPS public IP, bypassing AWS ALB).
  all_hosts   = concat([var.host_header], var.alt_host_headers)
  router_rule = join(" || ", [for h in local.all_hosts : "Host(`${h}`)"])

  # Traefik dockerLabels — HTTP workloads get 2 routers on the same service:
  #   1. web (:80) — plain HTTP, used by AWS ALB TG-vps forwards and initial LE challenge
  #   2. websecure (:443) — HTTPS with Let's Encrypt cert (auto-emitted via HTTP challenge
  #      on first request; requires public DNS resolving to the VPS public IP, which is
  #      the case for alt_host_headers like direct.kriolu-kloud.cv)
  traefik_labels = local.is_http && var.host_header != "" ? {
    "traefik.enable" = "true"

    # HTTP router (port 80)
    "traefik.http.routers.${local.router_alias}.rule"        = local.router_rule
    "traefik.http.routers.${local.router_alias}.entrypoints" = var.traefik_entrypoint

    # HTTPS router (port 443) — same rule, TLS with Let's Encrypt
    "traefik.http.routers.${local.router_alias}-tls.rule"             = local.router_rule
    "traefik.http.routers.${local.router_alias}-tls.entrypoints"      = "websecure"
    "traefik.http.routers.${local.router_alias}-tls.tls"              = "true"
    "traefik.http.routers.${local.router_alias}-tls.tls.certresolver" = "letsencrypt"

    # Backend (shared by both routers)
    "traefik.http.services.${local.router_alias}.loadbalancer.server.port"          = tostring(var.container_port)
    "traefik.http.services.${local.router_alias}.loadbalancer.healthcheck.path"     = "/health"
    "traefik.http.services.${local.router_alias}.loadbalancer.healthcheck.interval" = "10s"
    "traefik.http.services.${local.router_alias}.loadbalancer.healthcheck.timeout"  = "3s"
  } : {}

  docker_labels = merge(local.traefik_labels, var.extra_docker_labels)
}

resource "aws_cloudwatch_log_group" "vps" {
  name              = local.log_group
  retention_in_days = 1
}

resource "aws_ecs_task_definition" "vps" {
  family                   = local.full_name
  requires_compatibilities = ["EXTERNAL"]
  network_mode             = "bridge"
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = length(var.task_role_arn) > 0 ? var.task_role_arn : var.execution_role_arn

  container_definitions = jsonencode([{
    name      = var.container_name
    image     = "${var.ecr_repository_url}:${var.image_tag}"
    cpu       = 0
    memory    = var.memory
    essential = true

    portMappings = local.is_http ? [
      { containerPort = var.container_port, hostPort = 0, protocol = "tcp" }
    ] : []

    environment = [
      for k, v in var.environment_vars : { name = k, value = v }
    ]

    extraHosts = [
      for hostname, ip in var.extra_hosts : { hostname = hostname, ipAddress = ip }
    ]

    dockerLabels = local.docker_labels

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-region        = var.aws_region
        awslogs-group         = local.log_group
        awslogs-stream-prefix = "ecs"
      }
    }
  }])

  lifecycle {
    # container_definitions removed from ignore_changes: CI redeploy uses
    # --force-new-deployment on :latest tag (no task-def change), so TF is
    # the only writer here. Keeping the ignore blocked Traefik label updates.
    ignore_changes = [tags]
  }
}

resource "aws_ecs_service" "vps" {
  name            = local.full_name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.vps.arn
  desired_count   = var.desired_count
  launch_type     = "EXTERNAL"

  # Destroy hardening — CRITICAL para services EXTERNAL, que ficam presos
  # em DRAINING quando o VPS é deregistered antes do TF destroy correr.
  wait_for_steady_state = false
  force_delete          = true

  timeouts {
    delete = "5m"
  }

  enable_execute_command = true

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # Placement strategies are NOT supported for launch_type=EXTERNAL — omit.

  lifecycle {
    ignore_changes = [desired_count, task_definition, tags]
  }

  propagate_tags = "SERVICE"
}
