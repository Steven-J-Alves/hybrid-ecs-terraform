# ------- ECS Role and Policy-------
module "ecs_role" {
  source = "../../modules/iam"
  create_ecs_role    = true
  name               = var.iam_role_names["ecs"]
  name_ecs_task_role = var.iam_role_names["ecs_task_role"]
}

module "ecs_role_policy" {
  source = "../../modules/iam"
  name          = "${local.base_name}-ecs-ecr-role"
  create_policy = true
  attach_to     = module.ecs_role.name_role
}
