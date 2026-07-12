# ──────────────────────────────────────────────
# Variables de entorno: DEV — Fastory
# ──────────────────────────────────────────────
# Uso: terraform workspace select dev
#      terraform plan -var-file=environments/dev.tfvars
# ──────────────────────────────────────────────

environment  = "dev"
project_name = "fastory"
aws_region   = "us-east-1"

# ECS Fargate — recursos mínimos para desarrollo
backend_cpu           = 256 # 0.25 vCPU
backend_memory        = 512 # 512 MB
backend_desired_count = 1   # Una sola tarea

# Fargate Spot para ahorrar costos en dev
use_fargate_spot = true
