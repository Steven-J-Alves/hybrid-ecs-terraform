# bootstrap/ — Remote State Backend

Terraform stack that provisions the **S3 bucket and DynamoDB lock tables** used by every other stack in this repo. Must be applied **once**, before anything else.

---

## What it creates

### S3 Bucket — `kriolu-kloud-terraform-tfstates`
- **Versioning:** enabled (allows state rollback)
- **Encryption:** AES-256 server-side encryption
- **Public access:** fully blocked

Used as the remote backend by `network/`, `cluster/`, `apps/`, and `apps2/` stacks.

### DynamoDB Lock Tables (PAY_PER_REQUEST)

| Table | Stack that uses it |
|---|---|
| `kriolu-kloud-network-terraform-lock` | `network/environments/*/` |
| `kriolu-kloud-cluster-terraform-lock` | `cluster/environments/*/` |
| `kriolu-kloud-apps-terraform-lock` | `apps/app/environments/*/` |
| `kriolu-kloud-apps2-terraform-lock` | `apps/app2/environments/*/` |

Lock tables prevent concurrent `terraform apply` from corrupting state.

### IAM Policies — `bootstrap/iam/`

Managed policy JSON files (applied manually via AWS console or CLI) for the GitLab CI IAM users:

| File | Grants |
|---|---|
| `network-policy.json` | VPC, SG, ACM, S3 (state), DynamoDB (lock) |
| `cluster-policy.json` | ECS, EC2, ALB, IAM pass-role, S3 (state), DynamoDB (lock) |
| `apps-policy.json` | ECS tasks, ECR, Route53, RDS/Aurora, S3 (state), DynamoDB (lock) |

All use `<ACCOUNT_ID>` as a placeholder — replace with the real AWS account ID before attaching.

---

## State file location

```
bootstrap/terraform.tfstate   ← local, committed to git (intentional — this stack has no remote backend)
```

This is the **only** stack with local state. All other stacks use the S3 bucket that bootstrap creates.

---

## Apply order

```
bootstrap → network → cluster → apps/app + apps/app2
```

Destroy order (reverse):
```
apps/app + apps/app2 → cluster → network → bootstrap
```

---

## Outputs

| Output | Value |
|---|---|
| `tfstate_bucket_name` | `kriolu-kloud-terraform-tfstates` |
| `network_lock_table_name` | `kriolu-kloud-network-terraform-lock` |
| `cluster_lock_table_name` | `kriolu-kloud-cluster-terraform-lock` |
| `apps_lock_table_name` | `kriolu-kloud-apps-terraform-lock` |
| `apps2_lock_table_name` | `kriolu-kloud-apps2-terraform-lock` |

---

## Usage

```bash
cd cluster-ecs-terraform/bootstrap

export AWS_ACCESS_KEY_ID=<steven-prod-key>
export AWS_SECRET_ACCESS_KEY=<steven-prod-secret>
export AWS_DEFAULT_REGION=us-east-1

# Run via Docker (terraform not installed locally)
docker run --rm --user "$(id -u):$(id -g)" \
  -v "$(pwd):/workspace" -w /workspace \
  -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION \
  hashicorp/terraform:1.9 init

docker run --rm --user "$(id -u):$(id -g)" \
  -v "$(pwd):/workspace" -w /workspace \
  -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION \
  hashicorp/terraform:1.9 apply -auto-approve
```

> Use the `steven-prod` IAM key, not the CI key — CI keys don't have S3/DynamoDB create permissions until bootstrap has run.

---

## Gotchas

- **Do not add a remote backend to this stack.** It creates the bucket — it cannot use the bucket as its own backend. Local state is correct and intentional.
- **The local `terraform.tfstate` is committed to git** so the team can see what bootstrap created without needing AWS access.
- **DynamoDB tables use `PAY_PER_REQUEST`** — no provisioned capacity needed; lock tables get near-zero traffic.
