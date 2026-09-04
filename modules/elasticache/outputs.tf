output "redis_endpoint" {
  value = replace(aws_elasticache_cluster.redis_cluster.cache_nodes[0].address, ":6379", "")
}
