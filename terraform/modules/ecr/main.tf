# ──────────────────────────────────────────────
# Módulo ECR — Fastory
# ──────────────────────────────────────────────

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  repos       = ["backend", "grafana", "prometheus", "loki"]
}

resource "aws_ecr_repository" "repos" {
  for_each             = toset(local.repos)
  name                 = "${local.name_prefix}-${each.key}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_arn
  }

  tags = {
    Name = "${local.name_prefix}-${each.key}-repo"
  }
}

resource "aws_ecr_lifecycle_policy" "repos" {
  for_each   = toset(local.repos)
  repository = aws_ecr_repository.repos[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Mantener las últimas 10 imágenes taggeadas"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
