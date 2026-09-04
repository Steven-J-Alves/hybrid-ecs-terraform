# output "public_alb_url" {
#   value       = module.networking.alb_public
#   description = "URL Load Balancer Public"
# }

# output "private_alb_url" {
#   value       = module.networking.alb_private
#   description = "URL Load Balancer Private"
# }
output "alb_public" {
  value = module.networking.alb_public
}

output "alb_arn_public" {
  value = module.networking.alb_arn_public
}

output "https_listener_arn_public" {
  value = module.networking.https_listener_arn_public
}

output "alb_dns_public" {
  value = module.networking.alb_dns_public
}

output "alb_private" {
  value = module.networking.alb_private
}

output "alb_arn_private" {
  value = module.networking.alb_arn_private
}

output "https_listener_arn_private" {
  value = module.networking.https_listener_arn_private
}

output "ecs_cluster" {
  value       = module.ecs_clusters
  description = "ECS Cluster Module"
}

output "alb_dns_private" {
  value = module.networking.alb_dns_private
}

output "ecs_cluster_id" {
  value       = module.ecs_clusters.ecs_cluster_id
  description = "ECS Cluster ID"
}

output "ecs_cluster_name" {
  value       = module.ecs_clusters.ecs_cluster_name
  description = "ECS Cluster Name"
}

output "http_listener_arn_private" {
  value = module.networking.http_listener_arn_private
}
