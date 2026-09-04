# network/ — VPC & Security Groups

Terraform stack that provisions the entire network layer on AWS (us-east-1). It is the **foundation** for the `cluster/` and `apps/` stacks — they consume IDs from here via remote state or data sources.

---

## What it creates

### VPC
- **CIDR:** `10.220.0.0/16`
- **Region:** `us-east-1`
- **AZs:** `us-east-1a`, `us-east-1b`, `us-east-1c`, `us-east-1d`
- DNS hostnames and DNS support enabled
- Public IPs automatically assigned in public subnets

### Subnets (4 AZs × 3 tiers = 12 subnets)

| Tier | AZ-a | AZ-b | AZ-c | AZ-d | Purpose |
|---|---|---|---|---|---|
| Public | `10.220.0.0/20` | `10.220.16.0/20` | `10.220.32.0/20` | `10.220.48.0/20` | Public ALB, NAT GW |
| Private | `10.220.64.0/20` | `10.220.80.0/20` | `10.220.96.0/20` | `10.220.112.0/20` | ECS tasks, services |
| Database | `10.220.128.0/20` | `10.220.144.0/20` | `10.220.160.0/20` | `10.220.176.0/20` | Aurora PostgreSQL |

### Gateways & Routing
- **Internet Gateway** — for public subnets
- **NAT Gateway** — single NAT (cost-optimised), in `us-east-1a`, static EIP
- **Route tables:** public → IGW, private → NAT GW, database → isolated (no internet egress)

### DB Subnet Group
- Spans all 4 database subnets
- Used by Aurora PostgreSQL in the `apps/` stack

### Security Groups (5 SGs)

| SG | Ingress | Egress | Used by |
|---|---|---|---|
| `alb-public-sg` | all-all from VPC CIDR + `0.0.0.0/0` | all | Public ALB |
| `alb-private-sg` | all-all from VPC CIDR + `0.0.0.0/0` | all | Private ALB |
| `services-private-sg` | all-all from VPC CIDR + `0.0.0.0/0` | all | ECS services |
| `data-private-sg` | all-all from VPC CIDR + `0.0.0.0/0` | all | Aurora, ElastiCache |
| `ssh-private-sg` | all-all from VPC CIDR + `0.0.0.0/0` | all | EC2 instances / bastion |

---

## Terraform Backend

```hcl
backend "s3" {
  bucket         = "<tfstates-bucket>"
  region         = "us-east-1"
  key            = "network-terraform/homolog/kriolu-kloud-vpc-us-east-1.tfstate"
  dynamodb_table = "<network-lock-table>"
}
```

Supporting AWS resources (created manually before the first apply):
- S3 bucket for state storage
- DynamoDB table for state locking
- IAM CI user with a policy covering VPC + S3 + DynamoDB + RDS (required for the DB subnet group)

---

## Outputs

| Output | Description |
|---|---|
| `vpc_id` | VPC ID |
| `vpc_cidr_block` | VPC CIDR block |
| `private_subnets` | List of private subnet IDs (4) |
| `public_subnets` | List of public subnet IDs (4) |
| `nat_public_ips` | NAT Gateway public IP |
| `azs` | List of availability zones used |
| `security_group_id` | alb-public SG ID |
| `sg_id_alb_private` | alb-private SG ID |
| `sg_id_services_private` | services-private SG ID |
| `sg_id_data_private` | data-private SG ID |
| `sg_id_ssh_private` | ssh-private SG ID |

> **Note:** `database_subnets` and `database_subnet_group_name` exist in state but are not yet exposed as outputs — add them to `vpc-outputs.tf` when `cluster/` or `apps/` needs them.

---

## CI Pipeline

File: `network/.gitlab-ci.yml` (included by root `.gitlab-ci.yml`)

| Job | Trigger | Action |
|---|---|---|
| `network:validate` | push with changes under `network/**` | `terraform init` + `terraform validate` |
| `network:plan` | after validate | `terraform plan -out=tfplan` |
| `network:apply` | **manual** | `terraform apply -auto-approve` (re-plans) |
| `network:destroy` | **manual** | `terraform destroy -auto-approve` |

Runner: shell executor on VPS. Terraform runs via `docker run hashicorp/terraform:1.9 --user $(id -u):$(id -g)` to avoid root-owned files in the workspace.

GitLab CI variables set at the `ecs` group level: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION` — all protected and masked.

---

## Modules

| Module | Version | Source |
|---|---|---|
| `terraform-aws-modules/vpc/aws` | `5.13.0` | registry.terraform.io |
| `terraform-aws-modules/security-group/aws` | `5.2.0` | registry.terraform.io |

---

## Gotchas

- **`ingress_cidr_blocks` is required** in security-group modules when using `ingress_rules`. Without it, the module sets `cidr_blocks = null`, which causes a 5-minute provider timeout. All SGs must include `ingress_cidr_blocks = [module.vpc.vpc_cidr_block, "0.0.0.0/0"]`.
- **IAM policy needs `rds:CreateDBSubnetGroup`** — the VPC module automatically creates `aws_db_subnet_group` when `create_database_subnet_group = true`. This permission must be on the CI user's policy.
- **Single NAT Gateway** (`single_nat_gateway = true`) — reduces cost but sacrifices cross-AZ HA. Acceptable for homolog environments.
- **Database subnets have no internet egress** — `create_database_nat_gateway_route = false` and `create_database_internet_gateway_route = false`. Aurora does not need outbound internet access.

---

## Local Usage

```bash
cd cluster-ecs-terraform/network

export AWS_ACCESS_KEY_ID=<ci-user-key>
export AWS_SECRET_ACCESS_KEY=<ci-user-secret>
export AWS_DEFAULT_REGION=us-east-1

# Run via Docker (mirrors CI behaviour)
docker run --rm --user "$(id -u):$(id -g)" \
  -v "$(pwd):/workspace" -w /workspace \
  -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION \
  hashicorp/terraform:1.9 <command>

# Useful commands
terraform init -reconfigure
terraform plan
terraform apply -auto-approve
terraform output
terraform state list
terraform state rm '<address>'
terraform import '<address>' '<id>'
```
