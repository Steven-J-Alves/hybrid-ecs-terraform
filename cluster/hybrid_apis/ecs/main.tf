module "ecs_cluster_ec2" {
  source = "../../../modules/ecs_ec2/cluster"
  name   = "${var.base_name}"
  key_name = var.ec2_key_name
  security_groups = [var.sg_ssh.id]
  vpc_zone_identifier = var.data_private_subnets.ids
  tags = var.tags
  max_size = 10
  desired_capacity = 3
  min_size = 3
  node_role_name_prefix = "${var.base_name}-node-role"
  associate_public_ip = false

  # arm64 Graviton — must be explicit (root module defaults are x86)
  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = "t4g.small"
}
