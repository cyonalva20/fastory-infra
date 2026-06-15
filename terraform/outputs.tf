# ──────────────────────────────────────────────
# Outputs Globales
# ──────────────────────────────────────────────

output "aws_region" {
  description = "Región de AWS utilizada"
  value       = var.aws_region
}

output "project_name" {
  description = "Nombre del proyecto"
  value       = var.project_name
}

output "environment" {
  description = "Entorno actual de despliegue"
  value       = var.environment
}
