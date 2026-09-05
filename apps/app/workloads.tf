# Platform values resolved from remote state and data sources — shared across all workloads
locals {
  platform_cluster_id                = data.terraform_remote_state.hybrid_apis.outputs.ecs_cluster_id
  platform_cluster_name              = data.terraform_remote_state.hybrid_apis.outputs.ecs_cluster_name
  platform_private_listener_arn      = data.terraform_remote_state.hybrid_apis.outputs.https_listener_arn_private
  platform_private_http_listener_arn = try(data.terraform_remote_state.hybrid_apis.outputs.http_listener_arn_private, "")
  platform_public_listener_arn       = data.terraform_remote_state.hybrid_apis.outputs.https_listener_arn_public
  platform_allowed_cidrs             = [data.aws_vpc.crawler_vpc.cidr_block, var.kriolu_kloud_vpn]
  platform_private_subnets           = data.aws_subnets.private_subnets.ids
}

# ------- HTTP workloads — get TG + listener rule on private ALB -------

module "workload_api" {
  source = "../../modules/ecs_ec2/workload"

  name           = "api"
  app_name       = local.base_name
  type           = "http"
  container_name = var.container_name["app_api"]
  port           = var.port_api_app
  host_header    = var.app_api_host

  health_check_path    = "/health"
  health_check_matcher = "200-499"

  min_capacity  = 1
  max_capacity  = 15
  cpu_target    = 90
  memory_target = 80

  cluster_id                = local.platform_cluster_id
  cluster_name              = local.platform_cluster_name
  vpc_id                    = data.aws_vpc.crawler_vpc.id
  private_subnets           = local.platform_private_subnets
  allowed_cidrs             = local.platform_allowed_cidrs
  private_listener_arn      = local.platform_private_listener_arn
  private_http_listener_arn = local.platform_private_http_listener_arn
  execution_role_arn        = module.ecs_role.arn_role
  task_role_arn             = module.ecs_role.arn_role_ecs_task_role
  aws_region                = var.aws_region
}

module "workload_front" {
  source = "../../modules/ecs_ec2/workload"

  name           = "front"
  app_name       = local.base_name
  type           = "http"
  container_name = var.container_name["app_front"]
  port           = var.port_front_app
  host_header    = var.app_host

  health_check_path    = "/health"
  health_check_matcher = "200-399"

  min_capacity  = 1
  max_capacity  = 3
  cpu_target    = 80
  memory_target = 80

  cluster_id           = local.platform_cluster_id
  cluster_name         = local.platform_cluster_name
  vpc_id               = data.aws_vpc.crawler_vpc.id
  private_subnets      = local.platform_private_subnets
  allowed_cidrs        = local.platform_allowed_cidrs
  private_listener_arn = local.platform_private_listener_arn
  public_listener_arn  = local.platform_public_listener_arn
  public_host_header   = var.app_host
  execution_role_arn   = module.ecs_role.arn_role
  task_role_arn        = module.ecs_role.arn_role_ecs_task_role
  aws_region           = var.aws_region

  # Weighted split — X% of app.kriolu-kloud.cv traffic routes to VPS via Tailscale.
  # TG is defined in workloads_vps.tf (aws_lb_target_group.front_vps).
  vps_target_group_arn = aws_lb_target_group.front_vps.arn
  aws_weight           = 100 - var.vps_front_traffic_weight
  vps_weight           = var.vps_front_traffic_weight

  environment_vars = {
    API_URL = "http://${var.app_api_host}"
  }
}

# ------- Worker workloads — no ALB, no TG, no listener rule -------

module "workload_worker" {
  source = "../../modules/ecs_ec2/workload"

  name           = "worker"
  app_name       = local.base_name
  type           = "worker"
  container_name = var.container_name["app_worker"]

  min_capacity  = 1
  max_capacity  = 15
  cpu_target    = 80
  memory_target = 80

  cluster_id         = local.platform_cluster_id
  cluster_name       = local.platform_cluster_name
  vpc_id             = data.aws_vpc.crawler_vpc.id
  private_subnets    = local.platform_private_subnets
  allowed_cidrs      = local.platform_allowed_cidrs
  execution_role_arn = module.ecs_role.arn_role
  task_role_arn      = module.ecs_role.arn_role_ecs_task_role
  aws_region         = var.aws_region

  environment_vars = {
    API_URL = "http://${var.app_api_host}"
  }
}

module "workload_scheduler" {
  source = "../../modules/ecs_ec2/workload"

  name           = "scheduler"
  app_name       = local.base_name
  type           = "worker"
  container_name = var.container_name["app_scheduler"]

  min_capacity  = 1
  max_capacity  = 8
  cpu_target    = 80
  memory_target = 80

  cluster_id         = local.platform_cluster_id
  cluster_name       = local.platform_cluster_name
  vpc_id             = data.aws_vpc.crawler_vpc.id
  private_subnets    = local.platform_private_subnets
  allowed_cidrs      = local.platform_allowed_cidrs
  execution_role_arn = module.ecs_role.arn_role
  task_role_arn      = module.ecs_role.arn_role_ecs_task_role
  aws_region         = var.aws_region

  environment_vars = {
    API_URL = "http://${var.app_api_host}"
  }
}

module "workload_manager" {
  source = "../../modules/ecs_ec2/workload"

  name           = "manager"
  app_name       = local.base_name
  type           = "worker"
  container_name = var.container_name["app_manager"]

  min_capacity  = 1
  max_capacity  = 3
  cpu_target    = 80
  memory_target = 80

  cluster_id         = local.platform_cluster_id
  cluster_name       = local.platform_cluster_name
  vpc_id             = data.aws_vpc.crawler_vpc.id
  private_subnets    = local.platform_private_subnets
  allowed_cidrs      = local.platform_allowed_cidrs
  execution_role_arn = module.ecs_role.arn_role
  task_role_arn      = module.ecs_role.arn_role_ecs_task_role
  aws_region         = var.aws_region

  environment_vars = {
    API_URL = "http://${var.app_api_host}"
  }
}

