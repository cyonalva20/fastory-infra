# ──────────────────────────────────────────────
# Terraform Configuration — Fastory
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
# Security Groups (ALB, EC2, RDS, Redis),
# KMS Key y Secrets Manager.

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
# MÓDULO 4: COMPUTE (ALB + EC2 + ASG)
# ════════════════════════════════════════════════
# Application Load Balancer, Launch Template con Docker
# y X-Ray, Auto Scaling Group con IAM roles.

module "compute" {
  source = "./modules/compute"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  private_subnet_ids    = module.networking.private_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  ec2_security_group_id = module.security.ec2_security_group_id
}

# ════════════════════════════════════════════════
# MÓDULO 5: CACHE (ElastiCache Redis)
# ════════════════════════════════════════════════
# Cluster Redis para caché de aplicación y sesiones.

module "cache" {
  source = "./modules/cache"

  project_name            = var.project_name
  environment             = var.environment
  private_subnet_ids      = module.networking.private_subnet_ids
  redis_security_group_id = module.security.redis_security_group_id
}

# ════════════════════════════════════════════════
# MÓDULO 6: MESSAGING (SQS)
# ════════════════════════════════════════════════
# Cola SQS con Dead Letter Queue para procesamiento
# asíncrono de mensajes, cifrada con KMS.

module "messaging" {
  source = "./modules/messaging"

  project_name = var.project_name
  environment  = var.environment
  kms_key_arn  = module.security.kms_key_arn
}

# ════════════════════════════════════════════════
# MÓDULO 7: BACKUP (AWS Backup)
# ════════════════════════════════════════════════
# Vault de respaldo con plan diario y selección
# automática por tag (Backup=True).

module "backup" {
  source = "./modules/backup"

  project_name = var.project_name
  environment  = var.environment
  kms_key_arn  = module.security.kms_key_arn
}

# ════════════════════════════════════════════════
# MÓDULO 8: MONITORING (CloudWatch + SNS)
# ════════════════════════════════════════════════
# Alarmas de CloudWatch para CPU del ASG y hosts
# no saludables del ALB, con notificaciones via SNS.

module "monitoring" {
  source = "./modules/monitoring"

  project_name            = var.project_name
  environment             = var.environment
  asg_name                = module.compute.asg_name
  alb_arn_suffix          = module.compute.alb_arn_suffix
  target_group_arn_suffix = module.compute.target_group_arn_suffix
}

# ════════════════════════════════════════════════
# MÓDULO 9: STORAGE (S3 Frontend)
# ════════════════════════════════════════════════
# Bucket S3 para alojar el frontend estático
# con versionamiento y cifrado.

module "storage" {
  source = "./modules/storage"

  project_name = var.project_name
  environment  = var.environment
}

# ════════════════════════════════════════════════
# MÓDULO 10: CDN (CloudFront + ACM + WAF)
# ════════════════════════════════════════════════
# CDN global con doble origen (S3 frontend + ALB API).
# ACM y WAF se activan solo con dominio personalizado.
# NOTA: Comentado para la demo por restricciones de cuenta nueva en AWS.

/*
module "cdn" {
  source = "./modules/cdn"

  project_name                   = var.project_name
  environment                    = var.environment
  enable_custom_domain           = var.enable_custom_domain
  s3_frontend_bucket_domain_name = module.storage.frontend_bucket_domain_name
  s3_frontend_bucket_id          = module.storage.frontend_bucket_id
  alb_dns_name                   = module.compute.alb_dns_name
}
*/

# ════════════════════════════════════════════════
# MÓDULO 11: DNS (Route 53)
# ════════════════════════════════════════════════
# Hosted Zone y registros DNS para el dominio personalizado.
# Se activa solo con enable_custom_domain = true.
# NOTA: Comentado porque depende del CDN.

/*
module "dns" {
  source = "./modules/dns"

  project_name           = var.project_name
  environment            = var.environment
  enable_custom_domain   = var.enable_custom_domain
  cloudfront_domain_name = "" # module.cdn.cloudfront_domain_name
}
*/
