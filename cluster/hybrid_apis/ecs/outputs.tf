output "ecs_cluster" {
  value = module.ecs_cluster_ec2
}

output "ecs_cluster_id" {
  value = module.ecs_cluster_ec2.ecs_cluster_id
}

output "ecs_cluster_name" {
  value = module.ecs_cluster_ec2.ecs_cluster_name
}
