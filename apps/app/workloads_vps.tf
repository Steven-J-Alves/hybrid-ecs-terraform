# workloads_vps.tf — mirror of workloads.tf, but for the VPS side (ECS Anywhere)
#
# Same 5 workloads (api, front, worker, scheduler, manager), same image ECR,
# but launch_type=EXTERNAL, dockerLabels for Traefik discovery, extraHosts to
# make inter-service calls resolve to the local Traefik via host-gateway.
#
# Requires:
#   - VPS registered as ECS Anywhere container instance (Fase 5 done)
#   - Traefik attached to Docker default `bridge` network on VPS (Fase 5 done)
#
# Discovery via docker.sock: Traefik sees the containers appear in `bridge`
# with dockerLabels, auto-builds routers/services, WRR-balances across replicas.

# ---------------------------------------------------------------------------
# ECR URLs — data sources to the repos created by the AWS-side workload module
# (workloads.tf → module.workload_api.module.ecr.aws_ecr_repository...)
# ---------------------------------------------------------------------------

data "aws_ecr_repository" "api" {
  name       = "${local.base_name}-api"
  depends_on = [module.workload_api]
}
data "aws_ecr_repository" "front" {
  name       = "${local.base_name}-front"
  depends_on = [module.workload_front]
}
data "aws_ecr_repository" "worker" {
  name       = "${local.base_name}-worker"
  depends_on = [module.workload_worker]
}
data "aws_ecr_repository" "scheduler" {
  name       = "${local.base_name}-scheduler"
  depends_on = [module.workload_scheduler]
}
data "aws_ecr_repository" "manager" {
  name       = "${local.base_name}-manager"
  depends_on = [module.workload_manager]
}

# ---------------------------------------------------------------------------
# TG-vps for front — the public ALB weighted-forwards X% here.
# target_type = ip, target = VPS Tailscale IP. Public ALB reaches it via the
# CGNAT route (100.64.0.0/10) installed by hybrid-networking-terraform/tailscale-gw
# in all VPC route tables (public + private + db).
# Health check hits Traefik root → 200 (nginx placeholder) or wherever front lands.
# ---------------------------------------------------------------------------

variable "vps_tailscale_ip" {
  description = "Tailscale IP of the VPS acting as the second ALB target"
  type        = string
  default     = "100.73.87.120"
}

variable "vps_front_traffic_weight" {
  description = "Weight assigned to the VPS side in the front weighted forward (0-100). Set to 100 to fully cut over to VPS (AWS side gets weight 0 and stops receiving traffic)."
  type        = number
  default     = 100
}

variable "vps_api_traffic_weight" {
  description = "Weight assigned to the VPS side in the api weighted forward (0-100). Set to 100 to fully cut over to VPS."
  type        = number
  default     = 100
}

# One TG per ALB per workload — AWS ELBv2 rejects the same TG on more than
# one LB (TargetGroupAssociationLimit). All TGs point to the same Tailscale
# IP:80 (Traefik on VPS routes internally by Host header) and use the same
# /ping health check.
locals {
  # workload -> set of ALB scopes each needs its own TG on
  vps_tg_matrix = {
    front = toset(["pub", "pvt"])
    api   = toset(["pub", "pvt"])
  }
  # Flat set for for_each: [{workload, scope}]
  vps_tg_set = merge([
    for wl, scopes in local.vps_tg_matrix : {
      for scope in scopes : "${wl}-${scope}" => { workload = wl, scope = scope }
    }
  ]...)
}

resource "aws_lb_target_group" "vps" {
  for_each    = local.vps_tg_set
  name        = "${local.base_name}-${each.value.workload}-vps-${each.value.scope}"
  vpc_id      = data.aws_vpc.crawler_vpc.id
  target_type = "ip"
  port        = 80
  protocol    = "HTTP"

  # Hits Traefik's built-in /ping (enabled by role `traefik-ping`). Returns 200
  # only when Traefik itself is healthy — no Host header needed (ALB TGs cannot
  # send custom headers). When Traefik is down, ALB drains traffic away from
  # the VPS target, eliminating the 504s the split was surfacing to end users.
  health_check {
    path                = "/ping"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 10
    matcher             = "200"
  }
}

resource "aws_lb_target_group_attachment" "vps" {
  for_each          = local.vps_tg_set
  target_group_arn  = aws_lb_target_group.vps[each.key].arn
  target_id         = var.vps_tailscale_ip
  port              = 80
  availability_zone = "all" # ALB target_type=ip with off-VPC IP needs "all"
}

# Preserve existing TG state after rename front_vps -> vps (with workload prefix).
# Without these blocks TF would destroy the old TGs and try to create new ones,
# hitting AWS ResourceInUse (listener rule still references old ARN).
moved {
  from = aws_lb_target_group.front_vps["pub"]
  to   = aws_lb_target_group.vps["front-pub"]
}
moved {
  from = aws_lb_target_group.front_vps["pvt"]
  to   = aws_lb_target_group.vps["front-pvt"]
}
moved {
  from = aws_lb_target_group_attachment.front_vps["pub"]
  to   = aws_lb_target_group_attachment.vps["front-pub"]
}
moved {
  from = aws_lb_target_group_attachment.front_vps["pvt"]
  to   = aws_lb_target_group_attachment.vps["front-pvt"]
}

# ---------------------------------------------------------------------------
# extraHosts — inter-API calls resolve to Traefik on the host bridge gateway.
#
# ECS RegisterTaskDefinition requires a real IPv4 (does NOT accept the
# `host-gateway` alias — that's a Docker Compose extension). The default
# Docker `bridge` network gateway is always 172.17.0.1 on the host, so we
# hardcode it. If you ever change docker's `bip` config, update this.
# ---------------------------------------------------------------------------
locals {
  docker_bridge_gateway = "172.17.0.1"
  vps_extra_hosts = {
    (var.app_api_host) = local.docker_bridge_gateway
    (var.app_host)     = local.docker_bridge_gateway
  }
}

# ---------------------------------------------------------------------------
# HTTP workloads — get Traefik dockerLabels for routing
# ---------------------------------------------------------------------------

module "workload_api_vps" {
  source = "../../modules/ecs_ec2/workload_vps"

  app_name       = local.base_name
  name           = "api"
  type           = "http"
  container_name = var.container_name["app_api"]
  container_port = var.port_api_app
  host_header    = var.app_api_host

  cluster_id         = local.platform_cluster_id
  ecr_repository_url = data.aws_ecr_repository.api.repository_url
  execution_role_arn = module.ecs_role.arn_role
  task_role_arn      = module.ecs_role.arn_role_ecs_task_role
  aws_region         = var.aws_region

  desired_count = 1
  cpu           = 256
  memory        = 512

  environment_vars = {
    NODE_ENV = "production"
  }

  extra_hosts = local.vps_extra_hosts
}

module "workload_front_vps" {
  source = "../../modules/ecs_ec2/workload_vps"

  app_name       = local.base_name
  name           = "front"
  type           = "http"
  container_name = var.container_name["app_front"]
  container_port = var.port_front_app
  host_header    = var.app_host

  cluster_id         = local.platform_cluster_id
  ecr_repository_url = data.aws_ecr_repository.front.repository_url
  execution_role_arn = module.ecs_role.arn_role
  task_role_arn      = module.ecs_role.arn_role_ecs_task_role
  aws_region         = var.aws_region

  desired_count = 1
  cpu           = 256
  memory        = 512

  environment_vars = {
    API_URL = "http://${var.app_api_host}"
  }

  extra_hosts = local.vps_extra_hosts
}

# ---------------------------------------------------------------------------
# Worker workloads — no Traefik labels (no HTTP), only extraHosts + env
# ---------------------------------------------------------------------------

# Same ordering rule as workloads.tf — API up first, consumers after.
module "workload_worker_vps" {
  source = "../../modules/ecs_ec2/workload_vps"

  depends_on = [module.workload_api_vps]

  app_name       = local.base_name
  name           = "worker"
  type           = "worker"
  container_name = var.container_name["app_worker"]

  cluster_id         = local.platform_cluster_id
  ecr_repository_url = data.aws_ecr_repository.worker.repository_url
  execution_role_arn = module.ecs_role.arn_role
  task_role_arn      = module.ecs_role.arn_role_ecs_task_role
  aws_region         = var.aws_region

  desired_count = 1
  cpu           = 256
  memory        = 512

  environment_vars = {
    API_URL = "http://${var.app_api_host}"
  }

  extra_hosts = local.vps_extra_hosts
}

module "workload_scheduler_vps" {
  source = "../../modules/ecs_ec2/workload_vps"

  depends_on = [module.workload_api_vps]

  app_name       = local.base_name
  name           = "scheduler"
  type           = "worker"
  container_name = var.container_name["app_scheduler"]

  cluster_id         = local.platform_cluster_id
  ecr_repository_url = data.aws_ecr_repository.scheduler.repository_url
  execution_role_arn = module.ecs_role.arn_role
  task_role_arn      = module.ecs_role.arn_role_ecs_task_role
  aws_region         = var.aws_region

  desired_count = 1
  cpu           = 256
  memory        = 512

  environment_vars = {
    API_URL = "http://${var.app_api_host}"
  }

  extra_hosts = local.vps_extra_hosts
}

module "workload_manager_vps" {
  source = "../../modules/ecs_ec2/workload_vps"

  depends_on = [module.workload_api_vps]

  app_name       = local.base_name
  name           = "manager"
  type           = "worker"
  container_name = var.container_name["app_manager"]

  cluster_id         = local.platform_cluster_id
  ecr_repository_url = data.aws_ecr_repository.manager.repository_url
  execution_role_arn = module.ecs_role.arn_role
  task_role_arn      = module.ecs_role.arn_role_ecs_task_role
  aws_region         = var.aws_region

  desired_count = 1
  cpu           = 256
  memory        = 512

  environment_vars = {
    API_URL = "http://${var.app_api_host}"
  }

  extra_hosts = local.vps_extra_hosts
}
