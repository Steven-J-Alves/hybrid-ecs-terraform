output "rds_endpoint" {
  value     = module.prod_api_b.rds_endpoint
  sensitive = false
}

output "rds_port" {
  value = module.prod_api_b.rds_port
}
