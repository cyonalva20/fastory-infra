# ──────────────────────────────────────────────
# Terraform Configuration — Fastory
# Arquitectura: 100% Serverless (ECS Fargate)
# ──────────────────────────────────────────────

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# ──────────────────────────────────────────────
# Provider AWS con tags globales por defecto
# ──────────────────────────────────────────────

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# ════════════════════════════════════════════════
# MÓDULO 1: NETWORKING
# ════════════════════════════════════════════════
# VPC, Subredes (públicas y privadas), Internet Gateway,
# NAT Gateway, Route Tables y VPC Flow Logs.

module "networking" {
  source = "./modules/networking"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# ════════════════════════════════════════════════
# MÓDULO 2: SECURITY
# ════════════════════════════════════════════════
# Security Groups (ALB, ECS Fargate, RDS, EFS,
# Observabilidad), KMS Key y Secrets Manager.

module "security" {
  source = "./modules/security"

  project_name   = var.project_name
  environment    = var.environment
  vpc_id         = module.networking.vpc_id
  vpc_cidr       = var.vpc_cidr
  aws_account_id = var.aws_account_id
}

# ════════════════════════════════════════════════
# MÓDULO 3: DATABASE (RDS PostgreSQL + RDS Proxy)
# ════════════════════════════════════════════════
# Instancia RDS PostgreSQL con RDS Proxy para
# connection pooling y Secrets Manager para credenciales.

module "database" {
  source = "./modules/database"

  project_name          = var.project_name
  environment           = var.environment
  private_subnet_ids    = module.networking.private_subnet_ids
  rds_security_group_id = module.security.rds_security_group_id
  kms_key_arn           = module.security.kms_key_arn
}

# ════════════════════════════════════════════════
# MÓDULO 4: STORAGE (S3 Frontend)
# ════════════════════════════════════════════════
# Bucket S3 para alojar el frontend estático (React SPA)
# con versionamiento y cifrado.

module "storage" {
  source = "./modules/storage"

  project_name = var.project_name
  environment  = var.environment
}

# ════════════════════════════════════════════════
# MÓDULO 5: MONITORING (CloudWatch + SNS)
# ════════════════════════════════════════════════
# Alarmas de CloudWatch para ECS Fargate y ALB,
# con notificaciones via SNS.
# NOTA: Se actualizará en el Día 2 cuando se creen
# los módulos de ECS y Observabilidad.

# module "monitoring" {
#   source = "./modules/monitoring"
#
#   project_name = var.project_name
#   environment  = var.environment
#   # Se reconectará con los recursos ECS en el Día 2
# }

# ════════════════════════════════════════════════
# MÓDULOS DÍA 2 (Placeholders)
# ════════════════════════════════════════════════
# Los siguientes módulos se implementarán en el Día 2:
#
# module "ecr" { }           — Repositorios de imágenes Docker
# module "efs" { }           — Persistencia para Grafana y Loki
# module "ecs" { }           — Cluster, Task Definitions, Services
# module "observability" { } — Prometheus, Loki, Grafana en Fargate
