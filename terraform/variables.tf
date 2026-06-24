# ──────────────────────────────────────────────
# Variables Globales — Fastory
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

# ──────────────────────────────────────────────
# Networking
# ──────────────────────────────────────────────

variable "vpc_cidr" {
  description = "Bloque CIDR principal de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Lista de Zonas de Disponibilidad a utilizar"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDRs de las subredes públicas (uno por AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs de las subredes privadas (uno por AZ)"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

# ──────────────────────────────────────────────
# Security
# ──────────────────────────────────────────────

variable "aws_account_id" {
  description = "ID de la cuenta AWS (para la política de KMS)"
  type        = string
  default     = "099090990554"
}

# ──────────────────────────────────────────────
# Dominio personalizado (CDN + DNS)
# ──────────────────────────────────────────────

variable "enable_custom_domain" {
  description = "Habilitar dominio personalizado (ACM, WAF, Route 53). Desactivado para evitar costos."
  type        = bool
  default     = false
}
