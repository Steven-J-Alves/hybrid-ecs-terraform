resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "${var.cluster_id}-sng"
  subnet_ids = [var.subnets_id[0], var.subnets_id[1]]
}

resource "aws_elasticache_cluster" "redis_cluster" {
  cluster_id           = var.cluster_id
  engine               = var.engine
  node_type            = var.node_type
  num_cache_nodes      = var.num_cache_nodes
  port                 = 6379
  parameter_group_name = "p-hermes-redis7"
  security_group_ids   = var.security_group_ids
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name
}