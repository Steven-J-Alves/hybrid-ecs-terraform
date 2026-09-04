locals {
  platform_cluster_id                = data.terraform_remote_state.hybrid_apis.outputs.ecs_cluster_id
  platform_cluster_name              = data.terraform_remote_state.hybrid_apis.outputs.ecs_cluster_name
  platform_private_listener_arn      = data.terraform_remote_state.hybrid_apis.outputs.https_listener_arn_private
  platform_private_http_listener_arn = try(data.terraform_remote_state.hybrid_apis.outputs.http_listener_arn_private, "")
  platform_private_subnets           = data.aws_subnets.private.ids
  platform_allowed_cidrs             = [data.aws_vpc.main.cidr_block, var.kriolu_kloud_vpn]
}

module "workload" {
  source = "../../modules/ecs_ec2/workload"

  name           = "api"
  app_name       = local.base_name
  type           = "http"
  container_name = "container-${local.base_name}-api"
  port           = var.port
  host_header    = var.domain

  health_check_path    = var.health_check_path
  health_check_matcher = "200-499"

  min_capacity  = var.min_capacity
  max_capacity  = var.max_capacity
  cpu_target    = var.cpu_target
  memory_target = var.memory_target

  cluster_id                = local.platform_cluster_id
  cluster_name              = local.platform_cluster_name
  vpc_id                    = data.aws_vpc.main.id
  private_subnets           = local.platform_private_subnets
  allowed_cidrs             = local.platform_allowed_cidrs
  private_listener_arn      = local.platform_private_listener_arn
  private_http_listener_arn = local.platform_private_http_listener_arn
  execution_role_arn        = module.ecs_role.arn_role
  task_role_arn             = module.ecs_role.arn_role_ecs_task_role
  aws_region                = var.aws_region
}
