# Bootstrap Guide — Prerequisites for Terraform Stacks

This document covers the **5% that lives outside Terraform**: the one-time manual steps required before the three stacks (`network → cluster → apps`) can be applied on a fresh AWS account or after a full destroy+recreate.

Apply these in order. Steps 1–4 are idempotent — safe to re-run if unsure.

---

## Recreate order (full reference)

```
bootstrap/           ← Step 1 (Terraform, local state)
  ↓
IAM users + policies ← Steps 2–3 (AWS CLI, one-time)
  ↓
EC2 key pair         ← Step 4 (AWS CLI, one-time)
  ↓
Route53 zone         ← Step 5 (pre-existing — never destroy)
  ↓
network → cluster → apps  ← regular CI/Terraform
  ↓
ECR image rebuild    ← Step 6 (re-run CI pipelines)
```

---

## Step 1 — Bootstrap stack (S3 + DynamoDB lock tables)

Local state. Apply **before** any other stack — the S3 bucket and DynamoDB tables are the backend for everything else.

```bash
cd bootstrap/

export AWS_PROFILE=steven-prod   # admin credentials, not kk-terraform-ci

terraform init
terraform apply
```

Creates:
- S3 bucket `kriolu-kloud-terraform-tfstates` (versioned, encrypted, private)
- DynamoDB tables: `kriolu-kloud-network-terraform-lock`, `kriolu-kloud-cluster-terraform-lock`, `kriolu-kloud-apps-terraform-lock`, `kriolu-kloud-apps2-terraform-lock`

> **Note:** If the bucket already exists (e.g., partial destroy), `terraform import` first:
> ```bash
> terraform import aws_s3_bucket.tfstate kriolu-kloud-terraform-tfstates
> ```

---

## Step 2 — IAM user `kk-terraform-ci` (Terraform CI user)

Used by GitLab CI pipelines to run `terraform apply` for all three stacks.

### 2a. Create user and attach policies

```bash
export AWS_PROFILE=steven-prod

# Create user
aws iam create-user --user-name kk-terraform-ci

# Attach the three managed policies (create them first if they don't exist — see Step 2b)
aws iam attach-user-policy \
  --user-name kk-terraform-ci \
  --policy-arn arn:aws:iam::<ACCOUNT_ID>:policy/kk-terraform-network-policy

aws iam attach-user-policy \
  --user-name kk-terraform-ci \
  --policy-arn arn:aws:iam::<ACCOUNT_ID>:policy/kk-terraform-cluster-policy

aws iam attach-user-policy \
  --user-name kk-terraform-ci \
  --policy-arn arn:aws:iam::<ACCOUNT_ID>:policy/kk-terraform-apps-policy

# Create access key — save output securely
aws iam create-access-key --user-name kk-terraform-ci
```

Store the `AccessKeyId` and `SecretAccessKey` in GitLab group **ecs** (ID: 30) as protected+masked variables:
`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION` (= `us-east-1`).

### 2b. Create the three IAM managed policies

Save the three JSON files below and apply each:

```bash
aws iam create-policy \
  --policy-name kk-terraform-network-policy \
  --policy-document file://bootstrap/iam/network-policy.json

aws iam create-policy \
  --policy-name kk-terraform-cluster-policy \
  --policy-document file://bootstrap/iam/cluster-policy.json

aws iam create-policy \
  --policy-name kk-terraform-apps-policy \
  --policy-document file://bootstrap/iam/apps-policy.json
```

> Policy JSON files are stored in `bootstrap/iam/`. They are the source of truth for permissions.
> If updating an existing policy, use `create-policy-version --set-as-default` instead of `create-policy`.

---

## Step 3 — IAM user `gitlab-ci-apps-for-deploy` (build + deploy user)

Used by all 10 app repo CI pipelines to push images to ECR and trigger ECS rolling deployments.
This is a **separate user** from `kk-terraform-ci` — narrower permissions, no Terraform access.

### 3a. Create user

```bash
export AWS_PROFILE=steven-prod

aws iam create-user --user-name gitlab-ci-apps-for-deploy

# Create access key — save output securely
aws iam create-access-key --user-name gitlab-ci-apps-for-deploy
```

Store the credentials in GitLab group **test-apps/app2** (ID: 33) as protected variables:
`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION`, `ECR_REGISTRY` (= `<ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com`).

### 3b. Attach inline policy

```bash
aws iam put-user-policy \
  --user-name gitlab-ci-apps-for-deploy \
  --policy-name gitlab-ci-ecr-ecs \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "ECRLogin",
        "Effect": "Allow",
        "Action": "ecr:GetAuthorizationToken",
        "Resource": "*"
      },
      {
        "Sid": "ECRPush",
        "Effect": "Allow",
        "Action": [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ],
        "Resource": "arn:aws:ecr:us-east-1:<ACCOUNT_ID>:repository/*-app*"
      },
      {
        "Sid": "ECSdeploy",
        "Effect": "Allow",
        "Action": [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:DescribeTasks",
          "ecs:ListTasks"
        ],
        "Resource": [
          "arn:aws:ecs:us-east-1:<ACCOUNT_ID>:cluster/*-hybrid-apis",
          "arn:aws:ecs:us-east-1:<ACCOUNT_ID>:service/*-hybrid-apis/*-app*"
        ]
      },
      {
        "Sid": "ECSTaskDef",
        "Effect": "Allow",
        "Action": [
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "iam:PassRole"
        ],
        "Resource": "*"
      }
    ]
  }' \
  --region us-east-1
```

> The `*-app*` wildcard covers all current and future repos: `p-app-*`, `h-app-*`, `p-app2-*`, `h-app2-*`.
> Inline policy chosen over managed because the policy is user-specific and the 2048-byte limit fits with wildcards.

---

## Step 4 — EC2 key pair `kriolu-kloud-key`

The private key is stored at `devops/ecs/kriolu-kloud-key.pem`. AWS only stores the public key fingerprint — the PEM is not recoverable from AWS.

```bash
export AWS_PROFILE=steven-prod

# Extract public key from PEM and import
ssh-keygen -y -f devops/ecs/kriolu-kloud-key.pem > /tmp/kriolu-kloud-key.pub

aws ec2 import-key-pair \
  --key-name kriolu-kloud-key \
  --public-key-material fileb:///tmp/kriolu-kloud-key.pub \
  --region us-east-1

rm /tmp/kriolu-kloud-key.pub
```

> Run this **before** `terraform apply` on the cluster stack — the launch template references this key pair name.
> If the PEM file is lost, generate a new RSA key, update the PEM file, and re-import.

---

## Step 5 — Route53 hosted zone (pre-existing — never destroy)

The `kriolu-kloud.cv` hosted zone must exist in Route53 before running `terraform apply` on any stack.
Terraform reads it with `data "aws_route53_zone"` — it does not create or delete it.

The NS records at the domain registrar must point to this hosted zone's name servers.

**Do not destroy the hosted zone.** All Route53 records inside it (`app.kriolu-kloud.cv`, `app-h.kriolu-kloud.cv`, etc.) are managed by Terraform and will be recreated by `apps/` apply.

To verify the zone exists:
```bash
aws route53 list-hosted-zones-by-name \
  --dns-name kriolu-kloud.cv \
  --profile steven-prod \
  --query 'HostedZones[0].{Id:Id,Name:Name}' \
  --output table
```

---

## Step 6 — Rebuild ECR images (post-apply)

The `apps/` stacks create empty ECR repositories. ECS services start with desired=1 but running=0 until images are pushed.

After Terraform apply completes, trigger all 10 build+deploy CI pipelines:

```bash
TOKEN=$(sed -n '2p' ~/Desktop/openclaw-course/gitlab-creds)
BASE="https://gitlab.kriolu-kloud.cv"

# App1 — prod (main branch)
for proj_id in 21 22 23 24 25; do
  curl -sk --http1.1 -X POST -H "PRIVATE-TOKEN: $TOKEN" \
    "$BASE/api/v4/projects/$proj_id/pipeline" \
    -H "Content-Type: application/json" -d '{"ref":"main"}'
done

# App1 — homolog
for proj_id in 21 22 23 24 25; do
  curl -sk --http1.1 -X POST -H "PRIVATE-TOKEN: $TOKEN" \
    "$BASE/api/v4/projects/$proj_id/pipeline" \
    -H "Content-Type: application/json" -d '{"ref":"homolog"}'
done

# App2 — prod
for proj_id in 27 28 29 30 31; do
  curl -sk --http1.1 -X POST -H "PRIVATE-TOKEN: $TOKEN" \
    "$BASE/api/v4/projects/$proj_id/pipeline" \
    -H "Content-Type: application/json" -d '{"ref":"main"}'
done

# App2 — homolog
for proj_id in 27 28 29 30 31; do
  curl -sk --http1.1 -X POST -H "PRIVATE-TOKEN: $TOKEN" \
    "$BASE/api/v4/projects/$proj_id/pipeline" \
    -H "Content-Type: application/json" -d '{"ref":"homolog"}'
done
```

Then trigger the `deploy:prod` / `deploy:homolog` manual jobs for each pipeline once the build stage succeeds.

> **Expected time:** ~45–60 min for all 20 pipelines (builds are parallel; deploy jobs run sequentially on the single runner).

All builds use `docker buildx build --builder arm64-builder --platform linux/arm64` — the `arm64-builder` buildx instance must exist on the GitLab runner VPS:
```bash
ssh openclaw "docker buildx create --name arm64-builder --use || true"
```

---

## Verification checklist

```bash
# All 4 domains at 200
for d in app.kriolu-kloud.cv app2.kriolu-kloud.cv app-h.kriolu-kloud.cv app2-h.kriolu-kloud.cv; do
  echo "$d → $(curl -sk -o /dev/null -w '%{http_code}' https://$d)"
done

# ECS running counts
export AWS_PROFILE=steven-prod
for cluster in p-hybrid-apis h-hybrid-apis; do
  echo "=== $cluster ==="
  for svc in $(aws ecs list-services --cluster $cluster --region us-east-1 --output json | \
    python3 -c "import json,sys; [print(a.split('/')[-1]) for a in json.load(sys.stdin)['serviceArns']]"); do
    info=$(aws ecs describe-services --cluster $cluster --services $svc --region us-east-1 \
      --query 'services[0].[runningCount,desiredCount]' --output text 2>/dev/null)
    echo "  $svc: $info"
  done
done
```

Expected: all services at `1/1` (api + front + worker for both apps in prod; api + front for both apps in homolog — background workers may lag until app-level initialization is done).
