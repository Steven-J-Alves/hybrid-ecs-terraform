# ------- Creating Server Public ALB -------
module "alb_public" {
  source     = "../../../modules/alb"
  create_alb = true
  # enable_http    = true 
  name            = "${var.base_name}-public"
  subnets         = var.data_public_subnets.ids
  security_group  = [var.data_sg_alb_public.id]
  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = var.data_acm_certificate.arn
}

# ------- Creating Server Private ALB -------
module "alb_private" {
  source      = "../../../modules/alb"
  create_alb  = true
  internal    = true
  enable_http = true
  name        = "${var.base_name}-private"
  subnets         = var.data_private_subnets.ids
  security_group  = [var.data_sg_alb_private.id]
  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = var.data_acm_certificate_private.arn
}

