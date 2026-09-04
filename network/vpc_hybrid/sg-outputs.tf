# AWS EC2 Security Group Terraform Outputs
output "security_group_name" {
  description = "The name of the security group"
  value       = module.sg_alb_public.security_group_name
}

output "security_group_id" {
  description = "The name of the security group"
  value       = module.sg_alb_public.security_group_id
}

output "sg_name_alb_private" {
  description = "The name of the security group"
  value       = module.sg_alb_private.security_group_name
}

output "sg_id_alb_private" {
  description = "The name of the security group"
  value       = module.sg_alb_private.security_group_id
}

output "sg_name_data_private" {
  description = "The name of the security group"
  value       = module.sg_data_private.security_group_name
}

output "sg_id_data_private" {
  description = "The name of the security group"
  value       = module.sg_data_private.security_group_id
}

output "sg_name_services_private" {
  description = "The name of the security group"
  value       = module.sg_services_private.security_group_name
}

output "sg_id_services_private" {
  description = "The name of the security group"
  value       = module.sg_services_private.security_group_id
}

output "sg_name_ssh_private" {
  description = "The name of the security group"
  value       = module.sg_ssh_private.security_group_name
}

output "sg_id_ssh_private" {
  description = "The name of the security group"
  value       = module.sg_ssh_private.security_group_id
}
