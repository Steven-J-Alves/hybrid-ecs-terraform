data "aws_route53_zone" "public" {
  name = "kriolu-kloud.cv."
}

locals {
  alb_zone_id     = "Z35SXDOTRQ7X7K"
  private_alb_dns = data.terraform_remote_state.hybrid_apis.outputs.alb_dns_private
}

resource "aws_route53_record" "app" {
  zone_id         = data.aws_route53_zone.public.zone_id
  name            = var.domain
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = local.private_alb_dns
    zone_id                = local.alb_zone_id
    evaluate_target_health = false
  }
}
