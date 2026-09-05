# data/ stack

RDS PostgreSQL + ElastiCache Redis for the hybrid architecture. Both use the shared `data-private` security group from the network stack (allows intra-VPC + all-all — sufficient for lab).

**Status:** code ready, **NOT applied yet**. Deferred until hybrid cluster + apps validated.

## What it creates

| Resource | Config | Cost / month |
|---|---|---|
| RDS PostgreSQL `p-hybrid-app-postgres` | `db.t4g.small` single-AZ, 20 GB gp3, engine `postgres` 16.4 | ~$25 |
| ElastiCache Redis `p-hybrid-app-redis` | `cache.t4g.micro`, single node, Redis 7 | ~$12 |
| DB subnet group | Uses first 2 private subnets from network stack | — |
| Redis subnet group | Same | — |
| **Total** | | **~$37** |

## Dependencies

- `hybrid-ecs-terraform/bootstrap` applied (DynamoDB lock `kriolu-kloud-hybrid-data-terraform-lock`)
- `hybrid-ecs-terraform/network/environments/prod` applied + **network outputs.tf includes vpc/subnets/SG** (already updated)

## Apply (when ready — DO NOT run yet)

```bash
cd data/environments/prod
export TF_VAR_rds_db_password='<strong-password>'    # or -var-file=terraform.tfvars
AWS_PROFILE=steven-prod terraform init -reconfigure
AWS_PROFILE=steven-prod terraform plan
AWS_PROFILE=steven-prod terraform apply
```

## Backend

- S3 key: `hybrid-data/prod/kriolu-kloud-hybrid-data-us-east-1.tfstate`
- DynamoDB lock: `kriolu-kloud-hybrid-data-terraform-lock`

## Consumed by

- `apps/app/main.tf` — will reference postgres endpoint via env var passed to task defs (when apps are enabled)
- VPS-side services (via Tailscale route) — same endpoint, latency ~100ms (accepted trade-off H6)

## Verification (post-apply)

```bash
# From VPS (Tailscale must be up)
ssh openclaw "psql -h $(terraform output -raw postgres_endpoint) -U app_user -d app -c 'SELECT 1;'"
ssh openclaw "redis-cli -h $(terraform output -raw redis_endpoint) PING"
```

## Gotchas

- **`modules/rds/outputs.tf`** strips `:3306` from endpoint (MySQL default). For postgres (5432), the `replace()` is a no-op — endpoint returns `host:5432`. If you need only the host, strip port at consumer side.
- **`modules/elasticache/main.tf`** references parameter group `p-hermes-redis7` (hardcoded from origin). If that param group doesn't exist in your account, Redis creation fails. Fix: either create the param group manually, use AWS default `default.redis7`, or edit `modules/elasticache/main.tf`.
- **Destroy warning:** `terraform destroy` deletes RDS + snapshots (`skip_final_snapshot = false` in module, but review before destroy). Consider `aws rds create-db-snapshot` manually before destroy in prod-like envs.

## When to apply

1. Cluster + apps stacks validated
2. Real apps need persistence (currently in-memory OK for hybrid rede validation)
3. Ready to spend ~$37/month extra
