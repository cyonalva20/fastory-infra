# ──────────────────────────────────────────────
# Variables — Módulo Networking
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
# VPC
# ──────────────────────────────────────────────

variable "vpc_cidr" {
  description = "Bloque CIDR principal de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# ──────────────────────────────────────────────
# Zonas de Disponibilidad y Subredes
# ──────────────────────────────────────────────

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
