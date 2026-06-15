# ──────────────────────────────────────────────
# Variables Globales
# ──────────────────────────────────────────────

variable "aws_region" {
  description = "Región de AWS donde se desplegará la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto, usado en tags y nombres de recursos"
  type        = string
  default     = "fastory"
}

variable "environment" {
  description = "Entorno de despliegue (production, staging, development)"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "El entorno debe ser: production, staging o development."
  }
}
