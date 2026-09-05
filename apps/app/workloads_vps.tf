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
  name = "${local.base_name}-api"
  depends_on = [module.workload_api]
}
data "aws_ecr_repository" "front" {
  name = "${local.base_name}-front"
  depends_on = [module.workload_front]
}
data "aws_ecr_repository" "worker" {
  name = "${local.base_name}-worker"
  depends_on = [module.workload_worker]
}
data "aws_ecr_repository" "scheduler" {
  name = "${local.base_name}-scheduler"
  depends_on = [module.workload_scheduler]
}
data "aws_ecr_repository" "manager" {
  name = "${local.base_name}-manager"
  depends_on = [module.workload_manager]
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

  app_name           = local.base_name
  name               = "api"
  type               = "http"
  container_name     = var.container_name["app_api"]
  container_port     = var.port_api_app
  host_header        = var.app_api_host

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

  app_name           = local.base_name
  name               = "front"
  type               = "http"
  container_name     = var.container_name["app_front"]
  container_port     = var.port_front_app
  host_header        = var.app_host

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

module "workload_worker_vps" {
  source = "../../modules/ecs_ec2/workload_vps"

  app_name           = local.base_name
  name               = "worker"
  type               = "worker"
  container_name     = var.container_name["app_worker"]

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

  app_name           = local.base_name
  name               = "scheduler"
  type               = "worker"
  container_name     = var.container_name["app_scheduler"]

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

  app_name           = local.base_name
  name               = "manager"
  type               = "worker"
  container_name     = var.container_name["app_manager"]

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
