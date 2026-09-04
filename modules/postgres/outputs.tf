output "endpoint" {
  description = "Writer endpoint of the Aurora PostgreSQL cluster"
  value       = aws_rds_cluster.aurora_pg_cluster.endpoint
}

output "port" {
  description = "Port of the Aurora PostgreSQL cluster"
  value       = aws_rds_cluster.aurora_pg_cluster.port
}

output "database_name" {
  description = "Database name"
  value       = aws_rds_cluster.aurora_pg_cluster.database_name
}

output "master_username" {
  description = "Master username"
  value       = aws_rds_cluster.aurora_pg_cluster.master_username
  sensitive   = true
}
