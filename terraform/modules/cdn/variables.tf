# ──────────────────────────────────────────────
# Variables — Módulo CDN
# ──────────────────────────────────────────────

variable "project_name" {
  description = "Nombre del proyecto, usado en tags y nombres de recursos"
  type        = string
}

variable "environment" {
  description = "Entorno de despliegue (production, staging, development)"
  type        = string
}

# ──────────────────────────────────────────────
# Toggle para dominio personalizado
# ──────────────────────────────────────────────

variable "enable_custom_domain" {
  description = "Habilitar dominio personalizado (ACM + WAF). Desactivado por defecto para evitar costos."
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Nombre de dominio personalizado (ej. fastory.com)"
  type        = string
  default     = "fastory.com"
}

# ──────────────────────────────────────────────
# Orígenes (recibido de otros módulos)
# ──────────────────────────────────────────────

variable "s3_frontend_bucket_domain_name" {
  description = "Nombre de dominio del bucket S3 del frontend"
  type        = string
}

variable "s3_frontend_bucket_id" {
  description = "ID del bucket S3 del frontend"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name del ALB para el origen de la API"
  type        = string
}
