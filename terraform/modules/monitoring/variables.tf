# ──────────────────────────────────────────────
# Variables — Módulo Monitoring
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
# Auto Scaling Group (recibido del módulo compute)
# ──────────────────────────────────────────────

variable "asg_name" {
  description = "Nombre del Auto Scaling Group (para la dimensión de la alarma de CPU)"
  type        = string
}

# ──────────────────────────────────────────────
# ALB y Target Group (recibido del módulo compute)
# ──────────────────────────────────────────────

variable "alb_arn_suffix" {
  description = "Sufijo del ARN del ALB (para la dimensión de la alarma de hosts)"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Sufijo del ARN del Target Group (para la dimensión de la alarma de hosts)"
  type        = string
}
