# ──────────────────────────────────────────────
# Outputs Globales — Fastory
# ──────────────────────────────────────────────
# Valores finales que se muestran después del terraform apply.
# Útiles para configurar el backend, Ansible y el pipeline.
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

# ── Compute ──────────────────────────────────

output "alb_dns_name" {
  description = "URL del Application Load Balancer (acceso al backend)"
  value       = module.compute.alb_dns_name
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

# ── Cache ────────────────────────────────────

output "redis_endpoint" {
  description = "Endpoint del cluster ElastiCache Redis"
  value       = module.cache.redis_endpoint
  sensitive   = true
}

# ── Messaging ────────────────────────────────

output "sqs_queue_url" {
  description = "URL de la cola SQS principal"
  value       = module.messaging.queue_url
}

# ── CDN ──────────────────────────────────────

/*
output "cloudfront_url" {
  description = "URL del CDN CloudFront (acceso al frontend)"
  value       = module.cdn.cloudfront_domain_name
}
*/

output "s3_website_url" {
  description = "URL del S3 Bucket (acceso directo al frontend para demo)"
  value       = module.storage.frontend_website_endpoint
}

# ── Storage ──────────────────────────────────

output "frontend_bucket" {
  description = "ID del bucket S3 del frontend"
  value       = module.storage.frontend_bucket_id
}
