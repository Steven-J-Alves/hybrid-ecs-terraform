# modules/ — Reusable Terraform Modules

All modules used by `network/`, `cluster/`, and `apps/` stacks. Every module follows the same structure: `main.tf` + `variables.tf` + `outputs.tf`.

---

## Module map

```
modules/
├── alb/                    ← ALB, HTTPS/HTTP listeners, target groups
├── ecr/                    ← ECR repository per workload
├── securitygroup/          ← Security group with ingress/egress rules
├── iam/                    ← ECS task execution + task roles
├── s3/                     ← S3 bucket (general purpose)
├── rds_cluster/            ← Aurora PostgreSQL serverless cluster
├── postgres/               ← (older RDS-based variant, superseded by rds_cluster)
├── elasticache/            ← ElastiCache Redis cluster
├── ecs_ec2/                ← EC2-based ECS primitives (active)
│   ├── cluster/            ← ECS cluster + Capacity Provider + ASG + Launch Template
│   ├── workload/           ← Composite: full workload (ECR+SG+TG+listeners+task+service+autoscaling)
│   ├── service/            ← ECS service (bridge network mode)
│   ├── task_definition/    ← ECS task definition (bridge mode, hostPort=0)
│   └── autoscaling/        ← ECS service autoscaling (CPU + memory target tracking)
└── ecs/                    ← Fargate-based ECS primitives (legacy, not used in active stacks)
    ├── cluster/
    ├── service/
    ├── task_definition/
    └── autoscaling/
```

---

## Primitive modules

### `alb/`
Creates either an **ALB** or a **Target Group** (controlled by `create_alb` / `create_target_group` booleans).

| Variable | Description |
|---|---|
| `create_alb` | Create the ALB resource |
| `create_target_group` | Create a target group |
| `internal` | `true` = internal ALB |
| `enable_http` | Add an HTTP:80 listener (private ALB only) |
| `certificate_arn` | ACM cert for HTTPS listener |
| `tg_type` | `"instance"` (bridge mode) or `"ip"` (awsvpc) |
| `health_check_path` | Health check endpoint |

Outputs: `arn_alb`, `dns_alb`, `arn_listener_https`, `arn_listener` (HTTP), `arn_tg`.

---

### `ecr/`
Creates one **ECR repository** per workload.

| Variable | Description |
|---|---|
| `name` | Repository name (e.g., `p-app-api`) |

Outputs: `ecr_repository_url`.

---

### `securitygroup/`
Creates a **Security Group** with configurable ingress port.

| Variable | Description |
|---|---|
| `ingress_port` | Port to open. `0` = all TCP (used for worker tasks) |
| `cidr_blocks_ingress` | Allowed CIDRs (typically VPC CIDR) |

Outputs: `sg_id`.

---

### `iam/`
Creates the **ECS task execution role** and **task role** pair.

- Execution role: allows ECS to pull from ECR and write CloudWatch logs
- Task role: attached to the running container (for app-level AWS API calls)

Outputs: `execution_role_arn`, `task_role_arn`.

---

### `rds_cluster/`
Creates an **Aurora PostgreSQL** cluster (Serverless v2 or provisioned).

- Instance class: `db.t4g.large`
- Engine: Aurora PostgreSQL 17.x
- Placed in DB subnets (isolated, no internet egress)
- Uses `data-private-sg` security group

---

### `s3/`
General-purpose S3 bucket with versioning and encryption.

---

### `elasticache/`
ElastiCache Redis cluster. Not used in current active stacks.

---

## Composite module: `ecs_ec2/workload/`

The most important module in the repo. A single call to this module creates an entire workload (service + all its infrastructure).

```hcl
module "app_api" {
  source = "../../../modules/ecs_ec2/workload"

  type     = "http"           # "http" or "worker"
  app_name = "p-app"
  name     = "api"            # full_name = "p-app-api"

  # Networking
  vpc_id          = var.vpc_id
  private_subnets = var.private_subnets
  allowed_cidrs   = [var.vpc_cidr]

  # ALB listeners (from cluster/ outputs)
  private_listener_arn      = var.https_listener_arn_private
  private_http_listener_arn = var.http_listener_arn_private   # optional — HTTP:80
  public_listener_arn       = var.https_listener_arn_public   # optional — public exposure

  # DNS host headers
  host_header        = "app-api.kriolu-kloud.cv"
  public_host_header = ""   # empty = no public rule

  # Task sizing
  port    = 4004
  cpu     = 512
  memory  = 512

  # Autoscaling
  desired_count  = 1
  min_capacity   = 1
  max_capacity   = 3
  cpu_target     = 60
  memory_target  = 60

  # Health check
  health_check_path    = "/health"
  health_check_matcher = "200"

  # IAM + Cluster
  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.task_role_arn
  cluster_id         = var.cluster_id
  cluster_name       = var.cluster_name
  aws_region         = var.aws_region

  # Env vars injected into the container
  environment_vars = {
    NODE_ENV = "production"
    DB_URL   = "..."
  }
}
```

### What `type = "http"` creates

| Resource | Created? |
|---|---|
| ECR repository | Always |
| Security group | Always |
| Target group (private ALB) | Yes |
| Listener rule HTTPS:443 (private) | Yes |
| Listener rule HTTP:80 (private) | Only if `private_http_listener_arn` set |
| Target group (public ALB) | Only if `public_listener_arn` set |
| Listener rule HTTPS:443 (public) | Only if `public_listener_arn` set |
| Task definition | Always |
| ECS service | Always |
| Autoscaling | Always |

### What `type = "worker"` creates

| Resource | Created? |
|---|---|
| ECR repository | Yes |
| Security group | Yes (port 0 = all TCP from VPC) |
| Target group | No |
| Listener rules | No |
| Task definition | Yes (no port mappings) |
| ECS service | Yes |
| Autoscaling | Yes |

### Bridge network mode

All tasks run in **bridge** mode with `hostPort = 0`. ECS assigns a random ephemeral port on the EC2 host at runtime. The ALB target group (type `instance`) registers `EC2_IP:ephemeral_port` — no fixed port needed.

---

## Sub-modules called by `ecs_ec2/workload/`

### `ecs_ec2/task_definition/`
Creates an ECS task definition in bridge network mode.

- `network_mode = "bridge"`
- `hostPort = 0` → dynamic ephemeral port
- Container definitions injected as JSON

### `ecs_ec2/service/`
Creates an ECS service linked to the task definition and (optionally) ALB target groups.

- `use_load_balancer` — wires the service to target group(s)
- `health_check_grace_period_seconds = 15` (HTTP services only)
- Supports multiple target group registrations (private + public)

### `ecs_ec2/autoscaling/`
Application Auto Scaling for ECS services.

- Scales `ecs:service:DesiredCount` on the service
- Two policies: CPU tracking + memory tracking
- Scale-in cooldown: 60s

### `ecs_ec2/cluster/`
Creates the ECS cluster resource, Capacity Provider, and ASG.

- ASG uses a Launch Template (arm64 Graviton AMI via SSM)
- Managed scaling on the capacity provider
- Capacity providers registered: EC2 (default), FARGATE, FARGATE_SPOT

---

## Module dependency graph

```
apps/ stack
  └── workload/ (one per service)
        ├── ecr/
        ├── securitygroup/
        ├── alb/ (target group × 1 or 2)
        ├── ecs_ec2/task_definition/
        ├── ecs_ec2/service/
        └── ecs_ec2/autoscaling/

cluster/ stack
  ├── alb/ (full ALB × 2: public + private)
  └── ecs_ec2/cluster/ (ECS cluster + ASG + CP)

network/ stack
  ├── terraform-aws-modules/vpc    (community module)
  └── terraform-aws-modules/security-group (community module)
```

---

## Gotchas

- **`modules/ecs/` is not used in active stacks.** It was the original Fargate-based implementation, superseded by `modules/ecs_ec2/` when the project switched to EC2 Graviton instances. Do not use it for new workloads.
- **`ingress_port = 0`** in `securitygroup/` means all TCP, used for workers that don't receive HTTP traffic. It does not mean "no ingress".
- **`alb_priority = null`** on workload listener rules — AWS auto-assigns priority. If two workloads have overlapping host headers, set explicit priorities via `var.alb_priority`.
- **Adding one new workload** requires editing only the app's `main.tf` (one new module block). No changes to cluster/, network/, or shared modules needed.
