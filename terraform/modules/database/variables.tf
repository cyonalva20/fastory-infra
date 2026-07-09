# ──────────────────────────────────────────────
# Variables — Módulo Database
# ──────────────────────────────────────────────

variable "project_name" {
  description = "Nombre del proyecto, usado en tags y nombres de recursos"
  type        = string
}

variable "environment" {
  description = "Entorno de despliegue (production, staging, development)"
  type        = string
}

# ════════════════════════════════════════════════
# Red (recibido del módulo networking)
# ════════════════════════════════════════════════

variable "private_subnet_ids" {
  description = "Lista de IDs de las subredes privadas para el grupo de subredes de RDS"
  type        = list(string)
}

variable "rds_security_group_id" {
  description = "ID del Security Group de RDS"
  type        = string
}

# ════════════════════════════════════════════════
# Cifrado (recibido del módulo security)
# ════════════════════════════════════════════════

variable "kms_key_arn" {
  description = "ARN de la llave KMS para cifrado de almacenamiento y secretos"
  type        = string
}

# ════════════════════════════════════════════════
# Configuración de la base de datos
# ════════════════════════════════════════════════

variable "db_name" {
  description = "Nombre de la base de datos PostgreSQL"
  type        = string
  default     = "fastory_db"
}

variable "db_username" {
  description = "Usuario administrador de la base de datos"
  type        = string
  default     = "fastory_admin"
}

variable "db_port" {
  description = "Puerto de la base de datos PostgreSQL"
  type        = number
  default     = 5432
}
