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

# ════════════════════════════════════════════════
# MÓDULO 9: MONITORING (CloudWatch)
# ════════════════════════════════════════════════
module "monitoring" {
  source = "./modules/monitoring"

  project_name     = var.project_name
  environment      = var.environment
  ecs_cluster_name = module.ecs.cluster_name
  ecs_service_name = module.ecs.service_name
  alb_arn_suffix   = module.ecs.alb_arn_suffix
}

# ════════════════════════════════════════════════
# MÓDULO 5: ECR (Elastic Container Registry)
# ════════════════════════════════════════════════

module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
  environment  = var.environment
  kms_key_arn  = module.security.kms_key_arn
}

# ════════════════════════════════════════════════
# MÓDULO 6: EFS (Elastic File System)
# ════════════════════════════════════════════════

module "efs" {
  source = "./modules/efs"

  project_name          = var.project_name
  environment           = var.environment
  kms_key_arn           = module.security.kms_key_arn
  private_subnet_ids    = module.networking.private_subnet_ids
  efs_security_group_id = module.security.efs_security_group_id
}

# ════════════════════════════════════════════════
# MÓDULO 7: ECS CORE (Backend)
# ════════════════════════════════════════════════

module "ecs" {
  source = "./modules/ecs"

  project_name              = var.project_name
  environment               = var.environment
  vpc_id                    = module.networking.vpc_id
  public_subnet_ids         = module.networking.public_subnet_ids
  private_subnet_ids        = module.networking.private_subnet_ids
  alb_security_group_id     = module.security.alb_security_group_id
  ecs_security_group_id     = module.security.ecs_security_group_id
  backend_repository_url    = module.ecr.backend_repository_url
  backend_cpu               = var.backend_cpu
  backend_memory            = var.backend_memory
  backend_desired_count     = var.backend_desired_count
  use_fargate_spot          = var.use_fargate_spot
  db_credentials_secret_arn = module.security.db_credentials_secret_arn
  jwt_secret_arn            = module.security.jwt_secret_arn
  kms_key_arn               = module.security.kms_key_arn
}

# ════════════════════════════════════════════════
# MÓDULO 8: OBSERVABILITY (Prometheus, Loki, Grafana)
# ════════════════════════════════════════════════

module "observability" {
  source = "./modules/observability"

  project_name                    = var.project_name
  environment                     = var.environment
  vpc_id                          = module.networking.vpc_id
  private_subnet_ids              = module.networking.private_subnet_ids
  observability_security_group_id = module.security.observability_security_group_id
  ecs_cluster_id                  = module.ecs.cluster_id
  cloudmap_namespace_id           = module.ecs.cloudmap_namespace_id
  efs_file_system_id              = module.efs.file_system_id
  efs_grafana_access_point_id     = module.efs.grafana_access_point_id
  efs_loki_access_point_id        = module.efs.loki_access_point_id
  grafana_repository_url          = module.ecr.grafana_repository_url
  prometheus_repository_url       = module.ecr.prometheus_repository_url
  loki_repository_url             = module.ecr.loki_repository_url
  alb_listener_arn                = module.ecs.alb_listener_arn
  kms_key_arn                     = module.security.kms_key_arn
}
