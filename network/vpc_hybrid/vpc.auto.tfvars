# VPC Variables
vpc_name                               = "kriolu-kloud-vpc"
vpc_cidr_block                         = "10.220.0.0/16"
vpc_availability_zones                 = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
vpc_public_subnets                     = ["10.220.0.0/20", "10.220.16.0/20", "10.220.32.0/20", "10.220.48.0/20"]
vpc_private_subnets                    = ["10.220.64.0/20", "10.220.80.0/20", "10.220.96.0/20", "10.220.112.0/20"]
vpc_database_subnets                   = ["10.220.128.0/20", "10.220.144.0/20", "10.220.160.0/20", "10.220.176.0/20"]
vpc_create_database_subnet_group       = true
vpc_create_database_subnet_route_table = true
vpc_enable_nat_gateway                 = true
vpc_single_nat_gateway                 = true