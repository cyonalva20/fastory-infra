# ──────────────────────────────────────────────
# Variables — Módulo Security
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
# Red (recibido del módulo networking)
# ──────────────────────────────────────────────

variable "vpc_id" {
  description = "ID de la VPC donde se crearán los Security Groups"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR de la VPC para restringir reglas de egress"
  type        = string
}

# ──────────────────────────────────────────────
# Puertos de la aplicación
# ──────────────────────────────────────────────

variable "app_port" {
  description = "Puerto en el que corre la aplicación backend (Spring Boot)"
  type        = number
  default     = 8080
}

variable "db_port" {
  description = "Puerto de la base de datos PostgreSQL"
  type        = number
  default     = 5432
}

variable "redis_port" {
  description = "Puerto de ElastiCache Redis"
  type        = number
  default     = 6379
}

# ──────────────────────────────────────────────
# AWS Account
# ──────────────────────────────────────────────

variable "aws_account_id" {
  description = "ID de la cuenta AWS (para la política de KMS)"
  type        = string
  default     = "099090990554"
}
