/*=========================================
      AWS Elastic Container Registry
==========================================*/

resource "aws_ecr_repository" "ecr_repository" {
  name                 = var.name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

# ---------------------------------------------------------------------------
# Bootstrap placeholder image
#
# ECS services would otherwise fail to launch on first apply (empty ECR = no
# image to pull = tasks stop = service in ROLLBACK). This pushes nginx:alpine
# as the `:latest` tag right after ECR creation so the service arrives at
# steady state. CI overwrites `:latest` when it pushes the real image.
#
# Requires `docker` + `aws` CLI on the machine running `terraform apply`.
# The vps-native-runner has both. Set var.push_placeholder=false to skip.
# ---------------------------------------------------------------------------

resource "null_resource" "placeholder_image" {
  count = var.push_placeholder ? 1 : 0

  triggers = {
    ecr_url = aws_ecr_repository.ecr_repository.repository_url
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      REGISTRY="$(echo '${aws_ecr_repository.ecr_repository.repository_url}' | cut -d/ -f1)"
      REPO_URL="${aws_ecr_repository.ecr_repository.repository_url}"

      aws ecr get-login-password --region ${var.aws_region} \
        | docker login --username AWS --password-stdin "$REGISTRY"

      docker pull ${var.placeholder_image}
      docker tag  ${var.placeholder_image} "$REPO_URL:latest"
      docker push "$REPO_URL:latest"
    EOT
  }
}
