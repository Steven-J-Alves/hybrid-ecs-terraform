# Postgres outputs disabled — Aurora module is commented out in main.tf.
# Re-enable when migrating Postgres into the dedicated data/ stack.
#
# output "rds_endpoint" {
#   value     = module.rds_pg_cluster_app.endpoint
#   sensitive = false
# }
#
# output "rds_port" {
#   value = module.rds_pg_cluster_app.port
# }
