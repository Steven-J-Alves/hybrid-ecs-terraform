output "app_domain" {
  description = "Application hostname registered in Route53"
  value       = var.domain
}

output "base_name" {
  description = "Base resource name prefix (e.g. p-myapp)"
  value       = local.base_name
}
