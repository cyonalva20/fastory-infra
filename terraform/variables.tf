# ──────────────────────────────────────────────
# Variables Globales — Fastory
# ──────────────────────────────────────────────
# Estos valores se sobreescriben desde los archivos
# environments/dev.tfvars o environments/prod.tfvars
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
  description = "Entorno de despliegue (dev, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "El entorno debe ser: dev o prod."
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
# ECS Fargate
# ──────────────────────────────────────────────

variable "backend_cpu" {
  description = "CPU units para la tarea del backend (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "backend_memory" {
  description = "Memoria en MB para la tarea del backend"
  type        = number
  default     = 512
}

variable "backend_desired_count" {
  description = "Número deseado de tareas del backend en ejecución"
  type        = number
  default     = 1
}

variable "use_fargate_spot" {
  description = "Usar Fargate Spot para ahorrar costos (hasta 70% descuento)"
  type        = bool
  default     = true
}
