output "postgres_endpoint" {
  description = "RDS PostgreSQL endpoint (host:port — module strips :3306 which is a no-op for postgres:5432)"
  value       = module.postgres.db_instance_endpoint
}

output "postgres_identifier" {
  description = "RDS PostgreSQL instance identifier"
  value       = "${substr(var.environment_name, 0, 1)}-hybrid-app-postgres"
}

output "redis_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = module.redis.redis_endpoint
}

output "redis_cluster_id" {
  description = "ElastiCache Redis cluster ID"
  value       = "${substr(var.environment_name, 0, 1)}-hybrid-app-redis"
}
