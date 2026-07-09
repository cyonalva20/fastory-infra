# ──────────────────────────────────────────────
# Outputs — Módulo Database
# ──────────────────────────────────────────────
# Estos valores se exponen al root module para que
# otros módulos (compute, networking, etc.) puedan referenciarlos.
# ──────────────────────────────────────────────

# ── RDS ──────────────────────────────────────

output "db_endpoint" {
  description = "Endpoint de conexión de la instancia RDS PostgreSQL"
  value       = aws_db_instance.main.endpoint
}

output "db_name" {
  description = "Nombre de la base de datos"
  value       = aws_db_instance.main.db_name
}

output "db_port" {
  description = "Puerto de la base de datos"
  value       = aws_db_instance.main.port
}

# ── RDS Proxy ────────────────────────────────

output "proxy_endpoint" {
  description = "Endpoint del RDS Proxy (usar en lugar de db_endpoint)"
  value       = aws_db_proxy.main.endpoint
}

# ── Secrets ──────────────────────────────────

output "rds_credentials_secret_arn" {
  description = "ARN del secreto con credenciales de la BD para el proxy"
  value       = aws_secretsmanager_secret.rds_credentials.arn
}
