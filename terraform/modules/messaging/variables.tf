# ──────────────────────────────────────────────
# Variables — Módulo Messaging
# ──────────────────────────────────────────────

variable "project_name" {
  description = "Nombre del proyecto, usado en tags y nombres de recursos"
  type        = string
}

variable "environment" {
  description = "Entorno de despliegue (production, staging, development)"
  type        = string
}

# Cifrado (recibido del módulo security)

variable "kms_key_arn" {
  description = "ARN de la llave KMS para cifrado de las colas SQS"
  type        = string
}
