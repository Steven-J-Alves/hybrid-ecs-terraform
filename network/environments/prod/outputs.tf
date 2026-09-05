output "acm_certificate_arn" {
  description = "ARN of the wildcard ACM certificate for kriolu-kloud.cv"
  value       = module.vpc_hybrid.acm_certificate_arn
}

# Outputs used as remote state by downstream stacks (data, cluster, apps)

output "vpc_id" {
  description = "The ID of the hybrid VPC"
  value       = module.vpc_hybrid.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the hybrid VPC (10.230.0.0/16)"
  value       = module.vpc_hybrid.vpc_cidr_block
}

output "private_subnets" {
  description = "List of private subnet IDs (compute)"
  value       = module.vpc_hybrid.private_subnets
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc_hybrid.public_subnets
}

output "azs" {
  description = "AZs used by the VPC"
  value       = module.vpc_hybrid.azs
}

output "sg_id_data_private" {
  description = "Security group ID for data-private (RDS, ElastiCache)"
  value       = module.vpc_hybrid.sg_id_data_private
}

output "sg_id_services_private" {
  description = "Security group ID for services-private (ECS tasks)"
  value       = module.vpc_hybrid.sg_id_services_private
}

output "sg_id_alb_public" {
  description = "Security group ID for public ALB"
  value       = module.vpc_hybrid.security_group_id
}

output "sg_id_alb_private" {
  description = "Security group ID for private ALB"
  value       = module.vpc_hybrid.sg_id_alb_private
}
