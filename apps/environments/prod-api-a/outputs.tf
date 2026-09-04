output "rds_endpoint" {
  value     = module.prod_api_a.rds_endpoint
  sensitive = false
}

output "rds_port" {
  value = module.prod_api_a.rds_port
}
