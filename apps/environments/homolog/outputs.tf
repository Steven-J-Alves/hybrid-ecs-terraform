output "rds_endpoint" {
  value     = module.homolog_app.rds_endpoint
  sensitive = false
}

output "rds_port" {
  value = module.homolog_app.rds_port
}
