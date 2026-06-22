# ──────────────────────────────────────────────
# Módulo Security — Fastory
# ──────────────────────────────────────────────
# Recursos: Security Groups, KMS Key, Secrets Manager
# ──────────────────────────────────────────────

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ════════════════════════════════════════════════
# 1. SECURITY GROUP — ALB (Application Load Balancer)
# ════════════════════════════════════════════════
# Permite tráfico HTTP/HTTPS desde internet.

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Security Group para el Application Load Balancer"
  vpc_id      = var.vpc_id

  # HTTP desde internet
  ingress {
    description = "HTTP desde internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS desde internet
  ingress {
    description = "HTTPS desde internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # [FIX CKV_AWS_382] Egress restringido al puerto de la app
  egress {
    description = "Trafico hacia instancias EC2"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "${local.name_prefix}-alb-sg"
  }
}

# ════════════════════════════════════════════════
# 2. SECURITY GROUP — EC2 (Instancias de la App)
# ════════════════════════════════════════════════
# Solo permite tráfico desde el ALB en el puerto de la app.

resource "aws_security_group" "ec2" {
  name        = "${local.name_prefix}-ec2-sg"
  description = "Security Group para las instancias EC2 del ASG"
  vpc_id      = var.vpc_id

  # Tráfico desde el ALB al puerto de la app (Spring Boot 8080)
  ingress {
    description     = "Trafico desde ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # [FIX CKV_AWS_382] Egress restringido a puertos específicos
  egress {
    description = "HTTPS para descargar dependencias"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "PostgreSQL hacia RDS"
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Redis hacia ElastiCache"
    from_port   = var.redis_port
    to_port     = var.redis_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "${local.name_prefix}-ec2-sg"
  }
}

# ════════════════════════════════════════════════
# 3. SECURITY GROUP — RDS (Base de Datos PostgreSQL)
# ════════════════════════════════════════════════
# Solo permite tráfico desde las instancias EC2 en el puerto 5432.

resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "Security Group para RDS PostgreSQL"
  vpc_id      = var.vpc_id

  # PostgreSQL solo desde EC2
  ingress {
    description     = "PostgreSQL desde EC2"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  # [FIX CKV_AWS_382] Egress restringido a la VPC
  egress {
    description = "Respuestas dentro de la VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "${local.name_prefix}-rds-sg"
  }
}

# ════════════════════════════════════════════════
# 4. SECURITY GROUP — ElastiCache Redis
# ════════════════════════════════════════════════
# Solo permite tráfico desde las instancias EC2 en el puerto 6379.

resource "aws_security_group" "redis" {
  name        = "${local.name_prefix}-redis-sg"
  description = "Security Group para ElastiCache Redis"
  vpc_id      = var.vpc_id

  # Redis solo desde EC2
  ingress {
    description     = "Redis desde EC2"
    from_port       = var.redis_port
    to_port         = var.redis_port
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  # [FIX CKV_AWS_382] Egress restringido a la VPC
  egress {
    description = "Respuestas dentro de la VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "${local.name_prefix}-redis-sg"
  }
}

# ════════════════════════════════════════════════
# 5. KMS KEY — Cifrado de Secrets
# ════════════════════════════════════════════════
# Customer Managed Key para cifrar secretos en Secrets Manager.

resource "aws_kms_key" "main" {
  description             = "KMS key para cifrado de secretos de ${var.project_name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRootAccountFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.aws_account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-kms"
  }
}

resource "aws_kms_alias" "main" {
  name          = "alias/${local.name_prefix}-key"
  target_key_id = aws_kms_key.main.key_id
}

# ════════════════════════════════════════════════
# 6. SECRETS MANAGER — Credenciales de la aplicación
# ════════════════════════════════════════════════
# Solo se crean los "cascarones"; los valores reales se
# inyectan manualmente o por variables después.

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.project_name}/db-credentials"
  description = "Credenciales de la base de datos PostgreSQL"
  kms_key_id  = aws_kms_key.main.arn

  tags = {
    Name = "${local.name_prefix}-db-credentials"
  }
}

resource "aws_secretsmanager_secret" "jwt_secret" {
  name        = "${var.project_name}/jwt-secret"
  description = "Secreto JWT para autenticación del backend"
  kms_key_id  = aws_kms_key.main.arn

  tags = {
    Name = "${local.name_prefix}-jwt-secret"
  }
}
