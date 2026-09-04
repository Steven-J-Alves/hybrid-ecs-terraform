# hybrid-ecs-terraform

Terraform infrastructure for the **Kriolu Kloud hybrid VPS↔AWS architecture** — ECS EC2 Graviton cluster (AWS side) that pairs with ECS Anywhere tasks on the Contabo VPS.

Duplicated from [`cluster-ecs-terraform`](../cluster-ecs-terraform/) on 2026-09-04. Same 3-stack pattern (network → cluster → apps), renamed + isolated state to avoid conflict with the existing prod deployment.

See parent design at `.claude/topicos/hybrid-architecture/CONTEXTO.md` and diagrams at `../../networking/hybrid architecture/`.

---

## What this project owns (AWS side)

| # | Stack | What it creates |
|---|---|---|
| 0 | `bootstrap/` | IAM foundations (adjusted for hybrid) |
| 1 | `network/` | VPC `10.230.0.0/16`, subnets (public/private/DB), IGW, NAT, ACM |
| 2 | `cluster/` | ECS Cluster `hybrid-apis`, ALB public + private, ASG (Graviton Spot t4g) |
| 3 | `apps/` | ECS workloads `api-a` + `api-b` (task def, service EC2, workloads) |
| 4 | `data/` | **NEW stack** — RDS PostgreSQL t4g.small + ElastiCache Redis t4g.micro |

Apply order: `bootstrap → network → cluster → data → apps`

## What lives ELSEWHERE (don't duplicate here)

| Concern | Where |
|---|---|
| Tailscale subnet router (EC2 na VPC AWS) | `../../networking/hybrid architecture/hybrid-networking-terraform/tailscale-gw/` |
| ECS Anywhere SSM activation + IAM role | `hybrid-networking-terraform/ecs-anywhere-activation/` |
| Route53 private zone (kriolu-kloud.cv → VPC) | `hybrid-networking-terraform/dns/` |
| VPS-side config (Traefik multi-net, Tailscale, ECS agent) | `../../networking/hybrid architecture/hybrid-vps-ansible/` |

## Isolation from `cluster-ecs-terraform`

Same S3 state bucket, disjoint keys + own DynamoDB locks:

| Item | `cluster-ecs-terraform` (prod actual) | `hybrid-ecs-terraform` (novo) |
|---|---|---|
| VPC CIDR | 10.220.0.0/16 | **10.230.0.0/16** |
| State key prefixes | `network-terraform/`, `cluster-terraform/`, `apps-terraform/` | `hybrid-network/`, `hybrid-cluster/`, `hybrid-apps/` |
| DynamoDB locks | `kriolu-kloud-{network,cluster,apps,apps2}-terraform-lock` | `kriolu-kloud-hybrid-{network,cluster,apps,data}-terraform-lock` |
| IAM CI user | `kk-terraform-ci` | `kk-hybrid-terraform-ci` (to create) |
| ECS cluster | `p-ecs-cluster-main` / `h-...` | `p-hybrid-apis` / `h-hybrid-apis` |
| ALB names | `p-ecs-cluster-main-*` | `p-hybrid-apis-*` |
| App names | `app`, `app2` | `api-a`, `api-b` |

## Environments

| Environment | Cluster | App stack |
|---|---|---|
| prod | `p-hybrid-apis` | `p-hybrid-api-a-*`, `p-hybrid-api-b-*` |
| homolog | `h-hybrid-apis` | `h-hybrid-api-a-*`, `h-hybrid-api-b-*` |

## Modules

Reused from origin (independent copy — evolve without touching prod):
`alb`, `ecr`, `ecs`, `ecs_ec2/{autoscaling,cluster,service,task_definition,workload}`, `elasticache`, `iam`, `postgres`, `rds`, `rds_cluster`, `s3`, `securitygroup`.

## Pre-requisites (to create BEFORE first apply)

- [ ] IAM user `kk-hybrid-terraform-ci` + inline policies (mirror `kk-terraform-ci` scope)
- [ ] DynamoDB tables:
  - `kriolu-kloud-hybrid-network-terraform-lock`
  - `kriolu-kloud-hybrid-cluster-terraform-lock`
  - `kriolu-kloud-hybrid-apps-terraform-lock`
  - `kriolu-kloud-hybrid-data-terraform-lock`
- [ ] Ensure no overlap com `10.220.0.0/16` — hybrid usa `10.230.0.0/16`
- [ ] ACM cert `*.kriolu-kloud.cv` — reused from cluster-ecs-terraform
- [ ] Route53 hosted zone `kriolu-kloud.cv` — reused

## Local usage

Terraform via Docker (não instalar binário):

```bash
cd hybrid-ecs-terraform/<stack>/environments/<env>

docker run --rm --user "$(id -u):$(id -g)" \
  -v "$(realpath ../..):/workspace" -w /workspace/environments/<env> \
  -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION \
  hashicorp/terraform:1.9 <command>
```

## Doc drift note

BOOTSTRAP.md, `modules/README.md`, `cluster/README.md`, `apps/README.md` and other docs still reference the origin's `app`, `app2`, `p-app-*` naming in body text. Update opportunistically as hybrid stabilizes — code is correct.

## Origin

Duplicated 2026-09-04 from `cluster-ecs-terraform` @ commit ffff (to fill after `git log`). Renames via mass `sed` (6 batches). See `../../../.claude/topicos/hybrid-architecture/CONTEXTO.md` for design decisions H1-H9.
