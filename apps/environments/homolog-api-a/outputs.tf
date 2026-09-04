output "rds_endpoint" {
  value     = module.homolog_api_a.rds_endpoint
  sensitive = false
}

output "rds_port" {
  value = module.homolog_api_a.rds_port
}
