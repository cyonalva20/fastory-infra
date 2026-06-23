# ──────────────────────────────────────────────
# Variables — Módulo Compute
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
  description = "ID de la VPC donde se crearán los recursos de cómputo"
  type        = string
}

variable "public_subnet_ids" {
  description = "Lista de IDs de las subredes públicas (para el ALB)"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Lista de IDs de las subredes privadas (para las instancias EC2)"
  type        = list(string)
}

# ──────────────────────────────────────────────
# Security Groups (recibido del módulo security)
# ──────────────────────────────────────────────

variable "alb_security_group_id" {
  description = "ID del Security Group para el Application Load Balancer"
  type        = string
}

variable "ec2_security_group_id" {
  description = "ID del Security Group para las instancias EC2"
  type        = string
}

# ──────────────────────────────────────────────
# Instancia EC2
# ──────────────────────────────────────────────

variable "instance_type" {
  description = "Tipo de instancia EC2 para el Launch Template"
  type        = string
  default     = "t2.micro"
}

# ──────────────────────────────────────────────
# Auto Scaling Group
# ──────────────────────────────────────────────

variable "asg_min_size" {
  description = "Número mínimo de instancias en el ASG"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Número máximo de instancias en el ASG"
  type        = number
  default     = 2
}

variable "asg_desired_capacity" {
  description = "Número deseado de instancias en el ASG"
  type        = number
  default     = 1
}
