module "ecs_role" {
  source = "../../modules/iam"

  create_ecs_role    = true
  name               = "${local.base_name}-execution-role"
  name_ecs_task_role = "${local.base_name}-task-role"
}

module "ecs_role_policy" {
  source = "../../modules/iam"

  name          = "${local.base_name}-ecr-policy"
  create_policy = true
  attach_to     = module.ecs_role.name_role
}
