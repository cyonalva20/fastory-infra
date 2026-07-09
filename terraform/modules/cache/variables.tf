# ──────────────────────────────────────────────
# Variables — Módulo Cache
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

variable "private_subnet_ids" {
  description = "Lista de IDs de las subredes privadas (para el Subnet Group de Redis)"
  type        = list(string)
}

# ──────────────────────────────────────────────
# Security Group (recibido del módulo security)
# ──────────────────────────────────────────────

variable "redis_security_group_id" {
  description = "ID del Security Group para ElastiCache Redis"
  type        = string
}

# ──────────────────────────────────────────────
# Configuración del Cluster Redis
# ──────────────────────────────────────────────

variable "redis_node_type" {
  description = "Tipo de nodo de ElastiCache Redis"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_port" {
  description = "Puerto de ElastiCache Redis"
  type        = number
  default     = 6379
}
