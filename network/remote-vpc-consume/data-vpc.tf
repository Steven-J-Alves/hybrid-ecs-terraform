# Terraform Remote State Datasource
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "kriolu-kloud-terraform-tfstates"
    key    = "hybrid-network/homolog/kriolu-kloud-hybrid-vpc-us-east-1.tfstate"
    region = "us-east-1"
  }
}

/*
Usage Documentation:
vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
ingress_cidr_blocks = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block]
subnet_id = data.terraform_remote_state.vpc.outputs.public_subnets[0]
subnets = data.terraform_remote_state.vpc.outputs.public_subnets
vpc_zone_identifier = data.terraform_remote_state.vpc.outputs.private_subnets 
command = "echo VPC created on `date` and VPC ID: ${data.terraform_remote_state.vpc.outputs.vpc_id} >> creation-time-vpc-id.txt"
*/