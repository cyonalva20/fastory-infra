# ──────────────────────────────────────────────
# Outputs — Módulo Backup
# ──────────────────────────────────────────────
# Estos valores se exponen al root module para que
# otros módulos o configuraciones puedan referenciarlos.
# ──────────────────────────────────────────────

# ── AWS Backup ───────────────────────────────

output "backup_vault_arn" {
  description = "ARN del vault de respaldos"
  value       = aws_backup_vault.main.arn
}

output "backup_vault_name" {
  description = "Nombre del vault de respaldos"
  value       = aws_backup_vault.main.name
}

output "backup_plan_id" {
  description = "ID del plan de respaldo diario"
  value       = aws_backup_plan.daily.id
}
