
module "sg_services_private" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "5.2.0"
  name        = "services-private-sg"
  description = "Security Group with HTTP & SSH port open for entire VPC Block (IPv4 CIDR), egress ports are all world open"
  vpc_id      = module.vpc.vpc_id

  # ingress_rules = ["ssh-tcp", "http-80-tcp", "http-8080-tcp"]
  ingress_rules = ["all-all"]

  ingress_cidr_blocks = [module.vpc.vpc_cidr_block, "0.0.0.0/0"]
  egress_rules        = ["all-all"]
  tags                = local.common_tags
}
