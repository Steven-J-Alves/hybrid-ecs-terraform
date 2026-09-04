# Define the AWS Cloud Map private DNS namespace
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = var.namespace_name
  description = "Private DNS Namespace for ECS Service Discovery"
  vpc         = data.aws_vpc.kriolu_kloud_vpc.id
}

output "service_discovery_namespace_id" {
  description = "The ID of the Service Discovery Private DNS Namespace"
  value       = aws_service_discovery_private_dns_namespace.main.id
}
