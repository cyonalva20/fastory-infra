# ──────────────────────────────────────────────
# Variables de entorno: PROD — Fastory
# ──────────────────────────────────────────────
# Uso: terraform workspace select prod
#      terraform plan -var-file=environments/prod.tfvars
# ──────────────────────────────────────────────

environment  = "prod"
project_name = "fastory"
aws_region   = "us-east-1"

# ECS Fargate — recursos de producción
backend_cpu           = 512  # 0.5 vCPU
backend_memory        = 1024 # 1 GB
backend_desired_count = 2    # Alta disponibilidad

# Fargate estándar en producción (mayor estabilidad)
use_fargate_spot = false

# Auto Scaling — escala de 2 a 10 contenedores en producción
backend_min_capacity = 2
backend_max_capacity = 10
