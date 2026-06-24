# ──────────────────────────────────────────────
# Variables — Módulo DNS
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
  description = "Habilitar dominio personalizado en Route 53. Desactivado por defecto."
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Nombre de dominio (ej. fastory.com)"
  type        = string
  default     = "fastory.com"
}

# ──────────────────────────────────────────────
# Destinos (recibido de otros módulos)
# ──────────────────────────────────────────────

variable "cloudfront_domain_name" {
  description = "Nombre de dominio de la distribución CloudFront"
  type        = string
  default     = ""
}
