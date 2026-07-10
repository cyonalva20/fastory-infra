# ──────────────────────────────────────────────
# Módulo EFS — Fastory
# ──────────────────────────────────────────────
# Almacenamiento persistente para Grafana y Loki.
# ──────────────────────────────────────────────

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_efs_file_system" "main" {
  creation_token = "${local.name_prefix}-efs"
  encrypted      = true
  kms_key_id     = var.kms_key_arn

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "${local.name_prefix}-efs"
  }
}

resource "aws_efs_mount_target" "main" {
  count           = length(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [var.efs_security_group_id]
}

# ── Access Points ──

resource "aws_efs_access_point" "grafana" {
  file_system_id = aws_efs_file_system.main.id

  posix_user {
    gid = 472 # User ID de Grafana en la imagen oficial
    uid = 472
  }

  root_directory {
    path = "/grafana"
    creation_info {
      owner_gid   = 472
      owner_uid   = 472
      permissions = "755"
    }
  }

  tags = {
    Name = "${local.name_prefix}-grafana-ap"
  }
}

resource "aws_efs_access_point" "loki" {
  file_system_id = aws_efs_file_system.main.id

  posix_user {
    gid = 10001 # User ID de Loki en la imagen oficial
    uid = 10001
  }

  root_directory {
    path = "/loki"
    creation_info {
      owner_gid   = 10001
      owner_uid   = 10001
      permissions = "755"
    }
  }

  tags = {
    Name = "${local.name_prefix}-loki-ap"
  }
}
