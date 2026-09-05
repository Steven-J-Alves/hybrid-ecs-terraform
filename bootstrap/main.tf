# Bootstrap stack for the hybrid-ecs-terraform + hybrid-networking-terraform stacks.
# Uses local state (bootstrap/terraform.tfstate).
#
# The S3 state bucket `kriolu-kloud-terraform-tfstates` is SHARED with cluster-ecs-terraform
# and already exists — we reference it via data source instead of creating it.
#
# This bootstrap creates:
#   - DynamoDB lock tables for all 5 hybrid stacks (network, cluster, apps, data, networking)
#   - IAM user `kk-hybrid-terraform-ci` for CI apply, with inline policies from iam/*.json
#
# Apply once before running any other hybrid stack:
#   AWS_PROFILE=steven-prod terraform -chdir=bootstrap apply

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # intentionally local
}

provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------------------
# Reference to SHARED S3 state bucket (created by cluster-ecs-terraform bootstrap)
# ---------------------------------------------------------------------------

data "aws_s3_bucket" "tfstate" {
  bucket = "kriolu-kloud-terraform-tfstates"
}

# ---------------------------------------------------------------------------
# DynamoDB lock tables — one per hybrid stack
# ---------------------------------------------------------------------------

locals {
  lock_tables = {
    network    = "kriolu-kloud-hybrid-network-terraform-lock"
    cluster    = "kriolu-kloud-hybrid-cluster-terraform-lock"
    apps       = "kriolu-kloud-hybrid-apps-terraform-lock"
    data       = "kriolu-kloud-hybrid-data-terraform-lock"
    networking = "kriolu-kloud-hybrid-networking-terraform-lock"
  }
}

resource "aws_dynamodb_table" "lock" {
  for_each = local.lock_tables

  name         = each.value
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Project   = "kriolu-kloud"
    Stack     = each.key
    Scope     = "hybrid"
    ManagedBy = "terraform-bootstrap"
  }
}

# ---------------------------------------------------------------------------
# IAM user for CI apply — kk-hybrid-terraform-ci
# ---------------------------------------------------------------------------

resource "aws_iam_user" "ci" {
  name = "kk-hybrid-terraform-ci"

  tags = {
    Project   = "kriolu-kloud"
    Scope     = "hybrid"
    ManagedBy = "terraform-bootstrap"
  }
}

# Per-stack MANAGED policies (JSON files in iam/).
# Inline user policies have 2048-byte limit; managed policies have 6144 bytes,
# and IAM parses the pretty JSON. We use jsonencode(jsondecode(...)) to compact
# whitespace and stay well under the limit.
resource "aws_iam_policy" "network" {
  name        = "kk-hybrid-terraform-network-policy"
  description = "Terraform apply for hybrid-ecs-terraform/network stack"
  policy      = jsonencode(jsondecode(file("${path.module}/iam/network-policy.json")))
}

resource "aws_iam_policy" "cluster" {
  name        = "kk-hybrid-terraform-cluster-policy"
  description = "Terraform apply for hybrid-ecs-terraform/cluster stack"
  policy      = jsonencode(jsondecode(file("${path.module}/iam/cluster-policy.json")))
}

resource "aws_iam_policy" "apps" {
  name        = "kk-hybrid-terraform-apps-policy"
  description = "Terraform apply for hybrid-ecs-terraform/apps stack"
  policy      = jsonencode(jsondecode(file("${path.module}/iam/apps-policy.json")))
}

resource "aws_iam_user_policy_attachment" "network" {
  user       = aws_iam_user.ci.name
  policy_arn = aws_iam_policy.network.arn
}

resource "aws_iam_user_policy_attachment" "cluster" {
  user       = aws_iam_user.ci.name
  policy_arn = aws_iam_policy.cluster.arn
}

resource "aws_iam_user_policy_attachment" "apps" {
  user       = aws_iam_user.ci.name
  policy_arn = aws_iam_policy.apps.arn
}

# State backend permissions — needed by every stack for init/plan/apply
resource "aws_iam_user_policy" "state_backend" {
  name = "kk-hybrid-terraform-state-backend-policy"
  user = aws_iam_user.ci.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          data.aws_s3_bucket.tfstate.arn,
          "${data.aws_s3_bucket.tfstate.arn}/hybrid-*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = [for t in aws_dynamodb_table.lock : t.arn]
      }
    ]
  })
}

# Access key for CI
resource "aws_iam_access_key" "ci" {
  user = aws_iam_user.ci.name
}
