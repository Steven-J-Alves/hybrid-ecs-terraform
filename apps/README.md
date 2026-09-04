# apps/ — ECS Workloads

Terraform stack that deploys all ECS services (workloads) for a given application. Depends on `cluster/` outputs (cluster ID, ALB listener ARNs) via remote state.

See `apps/arch.drawio` for the full service communication diagram.

---

## Structure

```
apps/
├── arch.drawio              ← service communication diagram
├── app/                     ← app module (app-front, app-api, workers)
│   ├── workloads.tf         ← one module "workload" block per service
│   ├── main.tf              ← Aurora PostgreSQL cluster
│   ├── dns.tf               ← Route53 A alias records
│   ├── iam.tf               ← ECS execution role + task role
│   ├── data.tf              ← remote state + data source lookups
│   ├── locals.tf            ← base_name = "{env[0]}-app"
│   └── variables.tf
├── app2/                    ← identical pattern, second application
│   └── (same files as app/)
└── environments/
    ├── prod/                ← prod-app backend config + module call
    ├── prod-app2/           ← prod-app2 backend config + module call
    ├── homolog/             ← homolog-app backend config + module call
    └── homolog-app2/        ← homolog-app2 backend config + module call
```

---

## Workloads per app

### app (prod: `p-app-*`, homolog: `h-app-*`)

| Service | Type | Port | Host header | Public? | Autoscaling |
|---|---|---|---|---|---|
| `app-front` | http | 80 | `app.kriolu-kloud.cv` | Yes (ALB Public) | 1–3 tasks |
| `app-api` | http | 4004 | `app-api.kriolu-kloud.cv` | No (ALB Private only) | 1–15 tasks |
| `app-worker` | worker | — | — | No | 1–15 tasks |
| `app-scheduler` | worker | — | — | No | 1–8 tasks |
| `app-manager` | worker | — | — | No | 1–3 tasks |

### app2 (prod: `p-app2-*`, homolog: `h-app2-*`)

Same pattern as `app` with its own host headers and separate Aurora cluster.

---

## DNS records (Route53)

| Record | Points to | Purpose |
|---|---|---|
| `app.kriolu-kloud.cv` (prod) | ALB Public DNS (A alias) | Browser entry point |
| `app-api.kriolu-kloud.cv` (prod) | ALB Private DNS (A alias) | Internal API — Nginx proxy + worker direct calls |
| `app-h.kriolu-kloud.cv` (homolog) | ALB Public DNS | Homolog frontend |
| `app-api-h.kriolu-kloud.cv` (homolog) | ALB Private DNS | Homolog API |

---

## Database

Each app gets its own **Aurora PostgreSQL 17** cluster:
- Instance class: `db.t4g.large`
- DB name: `app` / `app2`
- User: `app_user`
- Placed in private subnets with `data-private-sg`
- Password: `TF_VAR_rds_db_password` (never committed to git)

---

## Terraform backend

```hcl
# prod / app
backend "s3" {
  bucket         = "kriolu-kloud-terraform-tfstates"
  key            = "apps-terraform/prod/kriolu-kloud-app-us-east-1.tfstate"
  dynamodb_table = "kriolu-kloud-apps-terraform-lock"
}

# prod / app2
backend "s3" {
  bucket         = "kriolu-kloud-terraform-tfstates"
  key            = "apps-terraform/prod-app2/kriolu-kloud-app2-us-east-1.tfstate"
  dynamodb_table = "kriolu-kloud-apps2-terraform-lock"
}
```

---

## How workloads consume the cluster

`data.tf` reads from `cluster/` remote state to resolve all shared infrastructure:

```hcl
data "terraform_remote_state" "hybrid_apis" {
  backend = "s3"
  config = {
    bucket = "kriolu-kloud-terraform-tfstates"
    key    = "cluster-terraform/{env}/kriolu-kloud-cluster-us-east-1.tfstate"
    region = "us-east-1"
  }
}
```

Resolved values shared across all workloads in `workloads.tf`:
- `platform_cluster_id` / `platform_cluster_name`
- `platform_private_listener_arn` (HTTPS:443)
- `platform_private_http_listener_arn` (HTTP:80 — for Node.js service-to-service)
- `platform_public_listener_arn` (HTTPS:443 — only front gets this)
- `platform_private_subnets`
- `platform_allowed_cidrs` (VPC CIDR + optional VPN IP)

---

## Adding a new workload

Edit `app/workloads.tf` and add one module block:

```hcl
module "workload_myservice" {
  source = "../../modules/ecs_ec2/workload"

  name           = "myservice"
  app_name       = local.base_name
  type           = "http"          # or "worker"
  container_name = "myservice"
  port           = 3000

  host_header          = "myservice.kriolu-kloud.cv"
  health_check_path    = "/health"
  health_check_matcher = "200"

  min_capacity  = 1
  max_capacity  = 5
  cpu_target    = 80
  memory_target = 80

  cluster_id           = local.platform_cluster_id
  cluster_name         = local.platform_cluster_name
  vpc_id               = data.aws_vpc.crawler_vpc.id
  private_subnets      = local.platform_private_subnets
  allowed_cidrs        = local.platform_allowed_cidrs
  private_listener_arn = local.platform_private_listener_arn
  execution_role_arn   = module.ecs_role.arn_role
  task_role_arn        = module.ecs_role.arn_role_ecs_task_role
  aws_region           = var.aws_region
}
```

No changes needed to `cluster/`, `network/`, or `modules/`. One block = full workload.

---

## Usage

```bash
cd cluster-ecs-terraform/apps/environments/prod

export AWS_ACCESS_KEY_ID=<ci-apps-key>
export AWS_SECRET_ACCESS_KEY=<ci-apps-secret>
export AWS_DEFAULT_REGION=us-east-1
export TF_VAR_rds_db_password=<db-password>

# Run via Docker
docker run --rm --user "$(id -u):$(id -g)" \
  -v "$(realpath ../..):/workspace" -w /workspace/environments/prod \
  -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION \
  -e TF_VAR_rds_db_password \
  hashicorp/terraform:1.9 apply -auto-approve
```

> Pre-requisite: `cluster/` must be applied first so the remote state output ARNs exist.

---

## CI Pipeline

GitLab CI jobs (`.gitlab-ci.yml`):

| Job | Trigger | Action |
|---|---|---|
| `apps:validate` | push with changes under `apps/**` | `terraform init` + `terraform validate` |
| `apps:plan` | after validate | `terraform plan -out=tfplan` |
| `apps:apply` | **manual** | `terraform apply -auto-approve` |
| `apps:destroy` | **manual** | `terraform destroy -auto-approve` |

`TF_VAR_rds_db_password` is set as a protected/masked CI variable at the GitLab group level.

---

## Gotchas

- **`TF_VAR_rds_db_password` must be set** or `terraform plan` fails — there is no default for the DB password.
- **`platform_private_http_listener_arn` uses `try(..., "")`** — if the cluster was applied before the HTTP:80 listener was added, the output may not exist. Re-apply the cluster first, then re-apply apps.
- **Workers use `API_URL = "http://${var.app_api_host}"`** — they call the API directly via the private ALB HTTP:80 listener, not through Nginx.
- **app-front has both `private_listener_arn` and `public_listener_arn`** — it registers in two target groups (private + public ALB), so it's reachable both internally and from the internet.
- **Route53 ALB zone ID is hardcoded** (`Z35SXDOTRQ7X7K`) — this is the fixed AWS zone ID for ALBs in `us-east-1`. Do not change it.
