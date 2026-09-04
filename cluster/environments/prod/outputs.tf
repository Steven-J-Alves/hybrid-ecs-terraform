output "ecs_cluster" {
  value = module.prod_hybrid_apis.ecs_cluster
}

output "ecs_cluster_id" {
  value = module.prod_hybrid_apis.ecs_cluster_id
}

output "ecs_cluster_name" {
  value = module.prod_hybrid_apis.ecs_cluster_name
}

# Public
output "alb_public" {
  value = module.prod_hybrid_apis.alb_public
}

output "alb_arn_public" {
  value = module.prod_hybrid_apis.alb_arn_public
}

output "https_listener_arn_public" {
  value = module.prod_hybrid_apis.https_listener_arn_public
}

output "alb_dns_public" {
  value = module.prod_hybrid_apis.alb_dns_public
}

# Private
output "alb_private" {
  value = module.prod_hybrid_apis.alb_private
}

output "alb_arn_private" {
  value = module.prod_hybrid_apis.alb_arn_private
}

output "https_listener_arn_private" {
  value = module.prod_hybrid_apis.https_listener_arn_private
}

output "alb_dns_private" {
  value = module.prod_hybrid_apis.alb_dns_private
}

output "http_listener_arn_private" {
  value = module.prod_hybrid_apis.http_listener_arn_private
}