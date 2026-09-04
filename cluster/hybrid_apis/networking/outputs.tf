# Public
output "alb_public" {
  value = module.alb_public
}

output "alb_arn_public" {
  value = module.alb_public.arn_alb
}

output "https_listener_arn_public" {
  value = module.alb_public.arn_listener_https
}

output "alb_dns_public" {
  value = module.alb_public.dns_alb
}

# Private
output "alb_private" {
  value = module.alb_private
}

output "alb_arn_private" {
  value = module.alb_private.arn_alb
}

output "https_listener_arn_private" {
  value = module.alb_private.arn_listener_https
}

output "alb_dns_private" {
  value = module.alb_private.dns_alb
}

output "http_listener_arn_private" {
  value = module.alb_private.arn_listener
}
