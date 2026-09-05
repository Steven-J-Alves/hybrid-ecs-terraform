#!/usr/bin/env bash
# Push arm64 nginx as :latest into every ECR repo of the hybrid apps stack.
# Run this AFTER `terraform apply` of the apps stack — before ECS services
# can reach steady state (empty ECR = tasks fail with ImagePull errors).
#
# Uses `docker buildx imagetools create` to copy a specific arm64/v8 digest
# directly to ECR — no local pull, no cross-arch emulation, works from any host.
# ECS cluster runs on Graviton (t4g), so arm64 is required.
#
# Requires: docker (with buildx) + aws CLI on the host.
# Usage:   ./scripts/push-placeholders.sh [prefix]
#          (default prefix: p-hybrid-app; use p-app when workloads are named p-app-*)
set -euo pipefail

: "${AWS_PROFILE:=steven-prod}"
: "${AWS_REGION:=us-east-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query Account --output text)
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
PREFIX="${1:-p-hybrid-app}"
WORKLOADS=(api front worker scheduler manager)

# nginx:alpine arm64/v8 digest (as of 2026-09-04)
# Refresh with:
#   docker buildx imagetools inspect nginx:alpine | grep -B2 'linux/arm64/v8'
NGINX_ARM64_DIGEST="sha256:ac1c5b25bb178c48d4f758b8a67021b45a5e6b056b8407364f060e162943f08b"
SOURCE="docker.io/library/nginx:alpine@${NGINX_ARM64_DIGEST}"

echo "→ login ECR ${REGISTRY}"
aws ecr get-login-password --region "$AWS_REGION" --profile "$AWS_PROFILE" \
  | docker login --username AWS --password-stdin "$REGISTRY"

for w in "${WORKLOADS[@]}"; do
  REPO="${REGISTRY}/${PREFIX}-${w}"
  echo "→ copy arm64 nginx → ${REPO}:latest"
  docker buildx imagetools create --tag "${REPO}:latest" "${SOURCE}"
done

echo "✓ done — 5 ECRs now have :latest arm64 placeholder"
