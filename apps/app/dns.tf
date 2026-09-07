data "aws_route53_zone" "public" {
  name = "kriolu-kloud.cv."
}

locals {
  alb_zone_id     = "Z35SXDOTRQ7X7K"
  public_alb_dns  = data.terraform_remote_state.hybrid_apis.outputs.alb_dns_public
  private_alb_dns = data.terraform_remote_state.hybrid_apis.outputs.alb_dns_private
}

resource "aws_route53_record" "app_front" {
  zone_id         = data.aws_route53_zone.public.zone_id
  name            = var.app_host
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = local.public_alb_dns
    zone_id                = local.alb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "app_api" {
  zone_id         = data.aws_route53_zone.public.zone_id
  name            = var.app_api_host
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = local.public_alb_dns
    zone_id                = local.alb_zone_id
    evaluate_target_health = false
  }
}

# Split DNS: api-internal.kriolu-kloud.cv -> private ALB (internal callers via
# VPN/Tailscale). Same TG (workload_api), different ingress point. Enables
# service-to-service without going out to the internet.
resource "aws_route53_record" "app_api_internal" {
  zone_id         = data.aws_route53_zone.public.zone_id
  name            = "api-internal.${trimsuffix(data.aws_route53_zone.public.name, ".")}"
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = local.private_alb_dns
    zone_id                = local.alb_zone_id
    evaluate_target_health = false
  }
}

# Direct-to-VPS DNS: bypasses the AWS ALB entirely. Requests land on the VPS
# public IPv4 (Contabo), served by Traefik on ports 80/443 with Let's Encrypt
# certs (HTTP challenge). Same containers as the AWS-side path — just no ALB hop.
variable "vps_public_ipv4" {
  description = "Contabo VPS public IPv4 for direct-to-VPS DNS records."
  type        = string
  default     = "161.97.83.115"
}

resource "aws_route53_record" "direct_app" {
  zone_id         = data.aws_route53_zone.public.zone_id
  name            = "direct.${trimsuffix(data.aws_route53_zone.public.name, ".")}"
  type            = "A"
  ttl             = 60
  records         = [var.vps_public_ipv4]
  allow_overwrite = true
}

resource "aws_route53_record" "direct_api" {
  zone_id         = data.aws_route53_zone.public.zone_id
  name            = "direct-api.${trimsuffix(data.aws_route53_zone.public.name, ".")}"
  type            = "A"
  ttl             = 60
  records         = [var.vps_public_ipv4]
  allow_overwrite = true
}
