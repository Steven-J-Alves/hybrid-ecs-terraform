output "rds_endpoint" {
  value     = module.rds_pg_cluster_app.endpoint
  sensitive = false
}

output "rds_port" {
  value = module.rds_pg_cluster_app.port
}
