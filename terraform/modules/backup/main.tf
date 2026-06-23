# ──────────────────────────────────────────────
# Módulo Backup — Fastory
# ──────────────────────────────────────────────
# Recursos: AWS Backup Vault, Plan de respaldo diario
# y selección de recursos por tag.
# ──────────────────────────────────────────────

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ════════════════════════════════════════════════
# BACKUP VAULT — Almacén de respaldos
# ════════════════════════════════════════════════

# Almacén cifrado donde se guardan los puntos de recuperación.
resource "aws_backup_vault" "main" {
  name        = "${local.name_prefix}-backup-vault"
  kms_key_arn = var.kms_key_arn

  tags = {
    Name = "${local.name_prefix}-backup-vault"
  }
}

# ════════════════════════════════════════════════
# BACKUP PLAN — Plan de respaldo diario
# ════════════════════════════════════════════════

# Respaldo automático diario con retención de 7 días.
resource "aws_backup_plan" "daily" {
  name = "${local.name_prefix}-daily-backup-plan"

  rule {
    rule_name         = "${local.name_prefix}-daily-rule"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 3 * * ? *)"  # Todos los días a las 03:00 UTC

    lifecycle {
      delete_after = 7  # Retención de 7 días
    }
  }

  tags = {
    Name = "${local.name_prefix}-daily-backup-plan"
  }
}

# ════════════════════════════════════════════════
# IAM ROLE — Para AWS Backup
# ════════════════════════════════════════════════

# Rol que permite a AWS Backup acceder a los recursos.
resource "aws_iam_role" "backup" {
  name = "${local.name_prefix}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-backup-role"
  }
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# ════════════════════════════════════════════════
# BACKUP SELECTION — Selección de recursos por tag
# ════════════════════════════════════════════════

# Selecciona automáticamente todos los recursos con el tag Backup=True.
resource "aws_backup_selection" "tagged_resources" {
  name         = "${local.name_prefix}-tagged-resources"
  plan_id      = aws_backup_plan.daily.id
  iam_role_arn = aws_iam_role.backup.arn

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Backup"
    value = "True"
  }
}
