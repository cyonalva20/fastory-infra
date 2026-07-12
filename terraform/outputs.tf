# ──────────────────────────────────────────────
# Outputs Globales — Fastory
# ──────────────────────────────────────────────
# Valores finales que se muestran después del terraform apply.
# Útiles para el pipeline CI/CD y verificación.
# ──────────────────────────────────────────────

# ── Entorno ──────────────────────────────────

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

# ── Networking ───────────────────────────────

output "vpc_id" {
  description = "ID de la VPC"
  value       = module.networking.vpc_id
}

# ── Database ─────────────────────────────────

output "db_endpoint" {
  description = "Endpoint de la instancia RDS PostgreSQL"
  value       = module.database.db_endpoint
  sensitive   = true
}

output "rds_proxy_endpoint" {
  description = "Endpoint del RDS Proxy (usar en lugar de db_endpoint)"
  value       = module.database.proxy_endpoint
  sensitive   = true
}

# ── Storage ──────────────────────────────────

output "frontend_bucket" {
  description = "ID del bucket S3 del frontend"
  value       = module.storage.frontend_bucket_id
}

output "s3_website_url" {
  description = "URL del S3 Bucket (acceso directo al frontend)"
  value       = module.storage.frontend_website_endpoint
}

# ── ECS / ECR (Día 2) ───────────────────────

output "ecr_repository_url" {
  description = "URL del repositorio ECR del backend"
  value       = module.ecr.backend_repository_url
}

output "ecs_cluster_name" {
  description = "Nombre del cluster ECS"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "Nombre del servicio ECS del backend"
  value       = module.ecs.service_name
}

output "alb_dns_name" {
  description = "URL del ALB (acceso al backend y Grafana)"
  value       = module.ecs.alb_dns_name
}

output "grafana_url" {
  description = "URL de Grafana (observabilidad)"
  value       = "http://${module.ecs.alb_dns_name}/grafana/"
}
