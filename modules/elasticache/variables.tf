variable "engine" {
  description = "Engine for the Redis Cluster"
  type        = string
  default     = "redis"
}

variable "node_type" {
  description = "Node Type for the Redis Cluster"
  type        = string
  default     = "cache.t4g.micro"
}

variable "num_cache_nodes" {
  description = "Number of Nodes for the Redis Cluster"
  type        = string
  default     = "1"
}

variable "cluster_id" {
  description = "Identifier for the Redis Cluster"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where the security group will take place"
  type        = string
}

variable "subnets_id" {
  description = "Subnet ID in which ecs will deploy the tasks"
  type        = list(string)
}
variable "security_group_ids" {
  description = "Set Security Groups IDS to Elasticache"
  type        = list(any)
}