# cluster/ — ECS Cluster + ALBs

Terraform stack that provisions the **ECS clusters, EC2 Auto Scaling Groups, and Application Load Balancers** shared by all workloads in an environment. The `apps/` stack depends on outputs from this stack.

---

## What it creates

### Application Load Balancers (2 per environment)

| ALB | Scheme | Listeners | Purpose |
|---|---|---|---|
| `{env}-hybrid-apis-public` | internet-facing | HTTPS:443 | Browser traffic → app-front containers |
| `{env}-hybrid-apis-private` | internal | HTTPS:443 + HTTP:80 | Service-to-service + Node.js internal calls |

- Public ALB uses ACM cert for `*.kriolu-kloud.cv`
- Private ALB uses a separate ACM private cert
- TLS policy: `ELBSecurityPolicy-TLS13-1-2-2021-06`
- Listener rules are added by individual workload modules in `apps/`

### ECS Cluster

| Resource | Value |
|---|---|
| Cluster name | `p-hybrid-apis` (prod) / `h-hybrid-apis` (homolog) |
| Capacity providers | EC2 (default), FARGATE, FARGATE_SPOT |
| Container Insights | enabled |

### EC2 Auto Scaling Group

| Setting | Value |
|---|---|
| Instance type | `t4g.small` (arm64 Graviton) |
| AMI | Latest ECS-optimised Amazon Linux 2 arm64 (via SSM: `/aws/service/ecs/optimized-ami/amazon-linux-2/arm64/recommended/image_id`) |
| Min / Desired / Max | 3 / 3 / 10 |
| Placement | Private subnets across 4 AZs |
| Public IP | disabled |
| SSH key | `kriolu-kloud-key` |

The ASG is linked to the cluster via an **ECS Capacity Provider** with managed scaling enabled.

### Cloud Map Service Discovery

- **Namespace:** `kriolu-kloud.local` (private DNS, VPC-scoped)
- Enables ECS services to register DNS names within the VPC

---

## Environments

| Directory | Cluster name | State key |
|---|---|---|
| `environments/prod/` | `p-hybrid-apis` | `cluster-terraform/prod/kriolu-kloud-cluster-us-east-1.tfstate` |
| `environments/homolog/` | `h-hybrid-apis` | `cluster-terraform/homolog/kriolu-kloud-cluster-us-east-1.tfstate` |

Both environments share the same VPC (created by `network/`). The `base_name` local is `{env_first_char}-hybrid-apis` — e.g., `p-` for prod, `h-` for homolog.

---

## Data sources (from network/)

This stack does **not** use remote state from `network/`. It discovers network resources via AWS data sources (tag-based filters):

| Filter variable | Default value | Matches |
|---|---|---|
| `subnet_public_filter` | `*kriolu-kloud-vpc-public*` | 4 public subnets |
| `subnet_private_filter` | `*kriolu-kloud-vpc-private*` | 4 private subnets |
| `sg_alb_public_filter` | `alb-public-sg` | Public ALB security group |
| `sg_alb_private_filter` | `alb-private-sg` | Private ALB security group |
| `sg_ssh_private_filter` | `ssh-private-sg` | EC2 SSH security group |

ACM certificates are discovered by domain name:
- Public: `*.kriolu-kloud.cv`
- Private: ACM private cert (same domain pattern)

---

## Terraform Backend

```hcl
backend "s3" {
  bucket         = "kriolu-kloud-terraform-tfstates"
  region         = "us-east-1"
  key            = "cluster-terraform/{env}/kriolu-kloud-cluster-us-east-1.tfstate"
  dynamodb_table = "kriolu-kloud-cluster-terraform-lock"
}
```

---

## Outputs (consumed by apps/)

| Output | Description |
|---|---|
| `ecs_cluster_id` | ECS Cluster ID |
| `ecs_cluster_name` | ECS Cluster name |
| `https_listener_arn_public` | Public ALB HTTPS:443 listener ARN |
| `https_listener_arn_private` | Private ALB HTTPS:443 listener ARN |
| `http_listener_arn_private` | Private ALB HTTP:80 listener ARN |
| `alb_dns_public` | Public ALB DNS name (used in Route53 A alias) |
| `alb_dns_private` | Private ALB DNS name |
| `alb_arn_public` | Public ALB ARN |
| `alb_arn_private` | Private ALB ARN |

---

## Module structure

```
cluster/
├── hybrid_apis/         ← reusable module
│   ├── main.tf               ← calls networking/ and ecs/ submodules
│   ├── locals.tf             ← base_name = "{env[0]}-{service_name}"
│   ├── data.tf               ← discovers VPC, subnets, SGs, ACM certs
│   ├── key_pair.tf           ← EC2 SSH key pair
│   ├── serivce-discoveryt.tf ← Cloud Map private DNS namespace
│   ├── networking/           ← creates ALB Public + ALB Private
│   └── ecs/                  ← creates ECS cluster + ASG + capacity provider
└── environments/
    ├── prod/                 ← prod backend config + module call
    └── homolog/              ← homolog backend config + module call
```

---

## Usage

```bash
cd cluster-ecs-terraform/cluster/environments/prod

export AWS_ACCESS_KEY_ID=<ci-cluster-key>
export AWS_SECRET_ACCESS_KEY=<ci-cluster-secret>
export AWS_DEFAULT_REGION=us-east-1

docker run --rm --user "$(id -u):$(id -g)" \
  -v "$(realpath ../..):/workspace" -w /workspace/environments/prod \
  -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION \
  hashicorp/terraform:1.9 init -reconfigure

docker run --rm --user "$(id -u):$(id -g)" \
  -v "$(realpath ../..):/workspace" -w /workspace/environments/prod \
  -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION \
  hashicorp/terraform:1.9 apply -auto-approve
```

> Pre-requisite: `network/` must be applied first so VPC, subnets, and SGs exist for the data source lookups.

---

## Gotchas

- **arm64 Graviton:** The ECS-optimised AMI SSM path is explicitly the arm64 variant. Do not change to `recommended/image_id` (that returns x86). `t4g.*` instances require arm64 AMIs.
- **ASG min=3 matches desired=3** — the capacity provider won't scale in below 3 even at zero task load. Adjust `min_size` for cost savings in homolog.
- **SSH key must exist** in the AWS account before apply. Create it manually: `aws ec2 create-key-pair --key-name kriolu-kloud-key`.
- **Service Discovery namespace** is per-environment (one per cluster). Apps register services here for DNS-based discovery within the VPC.
