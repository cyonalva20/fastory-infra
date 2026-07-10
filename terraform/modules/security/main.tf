# ──────────────────────────────────────────────
# Módulo Security — Fastory (ECS Fargate)
# ──────────────────────────────────────────────
# Recursos: Security Groups (ALB, ECS, RDS, EFS,
# Observability), KMS Key, Secrets Manager.
# ──────────────────────────────────────────────

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ════════════════════════════════════════════════
# 1. SECURITY GROUP — ALB (Application Load Balancer)
# ════════════════════════════════════════════════
# Permite tráfico HTTP/HTTPS desde internet.
# Egress hacia las tareas ECS Fargate y Grafana.

#checkov:skip=CKV2_AWS_5:Falso positivo. El SG se asocia al ALB en el modulo ecs
resource "aws_security_group" "alb" {
  # checkov:skip=CKV_AWS_260: "Ingress HTTP 80 requerido para ALB publico sin HTTPS."
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

  # Egress hacia tareas ECS (Backend 8080 + Grafana 3000)
  egress {
    description = "Trafico hacia tareas ECS Fargate"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Trafico hacia Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "${local.name_prefix}-alb-sg"
  }
}

# ════════════════════════════════════════════════
# 2. SECURITY GROUP — ECS Fargate (Tareas del Backend)
# ════════════════════════════════════════════════
# Solo permite tráfico desde el ALB en el puerto de la app.
# Egress hacia RDS, HTTPS (ECR/Secrets), y stack de observabilidad.

resource "aws_security_group" "ecs" {
  # checkov:skip=CKV2_AWS_5: "Falso positivo. El SG se asocia a las tareas ECS en el modulo ecs."
  name        = "${local.name_prefix}-ecs-sg"
  description = "Security Group para las tareas ECS Fargate del backend"
  vpc_id      = var.vpc_id

  # Tráfico desde el ALB al puerto de la app (Spring Boot 8080)
  ingress {
    description     = "Trafico desde ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Prometheus scraping desde el SG de observabilidad
  ingress {
    description     = "Prometheus scraping desde observabilidad"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.observability.id]
  }

  # HTTPS para ECR pull, Secrets Manager, CloudWatch Logs
  egress {
    description = "HTTPS para servicios AWS (ECR, Secrets, Logs)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # PostgreSQL hacia RDS
  egress {
    description = "PostgreSQL hacia RDS"
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Logs hacia Loki (observabilidad)
  egress {
    description = "Logs hacia Loki"
    from_port   = 3100
    to_port     = 3100
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # DNS para Service Discovery (Cloud Map)
  egress {
    description = "DNS para Service Discovery"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "DNS UDP para Service Discovery"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "${local.name_prefix}-ecs-sg"
  }
}

# ════════════════════════════════════════════════
# 3. SECURITY GROUP — RDS (Base de Datos PostgreSQL)
# ════════════════════════════════════════════════
# Solo permite tráfico desde las tareas ECS Fargate en el puerto 5432.

resource "aws_security_group" "rds" {
  # checkov:skip=CKV2_AWS_5: "Falso positivo. El SG se asocia a RDS en el modulo database."
  name        = "${local.name_prefix}-rds-sg"
  description = "Security Group para RDS PostgreSQL"
  vpc_id      = var.vpc_id

  # PostgreSQL solo desde ECS Fargate
  ingress {
    description     = "PostgreSQL desde ECS Fargate"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
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
# 4. SECURITY GROUP — EFS (Persistencia Observabilidad)
# ════════════════════════════════════════════════
# Permite NFS (2049) desde las tareas de observabilidad.

resource "aws_security_group" "efs" {
  # checkov:skip=CKV2_AWS_5: "Falso positivo. El SG se asocia a los mount targets en el modulo efs."
  name        = "${local.name_prefix}-efs-sg"
  description = "Security Group para EFS (persistencia de Grafana y Loki)"
  vpc_id      = var.vpc_id

  # NFS desde tareas de observabilidad
  ingress {
    description     = "NFS desde observabilidad"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.observability.id]
  }

  # [FIX CKV_AWS_382] Egress restringido
  egress {
    description = "Respuestas dentro de la VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "${local.name_prefix}-efs-sg"
  }
}

# ════════════════════════════════════════════════
# 5. SECURITY GROUP — Observabilidad (Prometheus, Loki, Grafana)
# ════════════════════════════════════════════════
# Permite comunicación entre los servicios de observabilidad
# y acceso desde el ALB hacia Grafana.

resource "aws_security_group" "observability" {
  # checkov:skip=CKV2_AWS_5: "Falso positivo. El SG se asocia a las tareas de observabilidad en el modulo observability."
  name        = "${local.name_prefix}-observability-sg"
  description = "Security Group para el stack de observabilidad (Prometheus, Loki, Grafana)"
  vpc_id      = var.vpc_id

  # Grafana desde ALB
  ingress {
    description     = "Grafana desde ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Prometheus desde la propia red de observabilidad (Grafana queries)
  ingress {
    description = "Prometheus queries internas"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    self        = true
  }

  # Loki desde la propia red (Grafana queries + Fluent Bit push)
  ingress {
    description = "Loki queries y push internas"
    from_port   = 3100
    to_port     = 3100
    protocol    = "tcp"
    self        = true
  }

  # Loki push desde ECS backend (Fluent Bit sidecar)
  ingress {
    description = "Loki push desde ECS backend (FireLens)"
    from_port   = 3100
    to_port     = 3100
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # HTTPS para ECR pull, CloudWatch Logs
  egress {
    description = "HTTPS para servicios AWS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Prometheus scraping al backend
  egress {
    description = "Prometheus scraping al backend"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Comunicación interna entre servicios de observabilidad
  egress {
    description = "Comunicacion interna observabilidad"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "Prometheus interno"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "Loki interno"
    from_port   = 3100
    to_port     = 3100
    protocol    = "tcp"
    self        = true
  }

  # NFS hacia EFS
  egress {
    description = "NFS hacia EFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # DNS para Service Discovery (Cloud Map)
  egress {
    description = "DNS para Service Discovery"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "DNS UDP para Service Discovery"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "${local.name_prefix}-observability-sg"
  }
}

# ════════════════════════════════════════════════
# 6. KMS KEY — Cifrado de Secrets
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
# 7. SECRETS MANAGER — Credenciales de la aplicación
# ════════════════════════════════════════════════
# Solo se crean los "cascarones"; los valores reales se
# inyectan manualmente o por variables después.

resource "aws_secretsmanager_secret" "db_credentials" {
  # checkov:skip=CKV2_AWS_57: "No implementaremos lambda de rotacion para la demo."
  name                    = "${var.project_name}/db-credentials"
  description             = "Credenciales de la base de datos PostgreSQL"
  kms_key_id              = aws_kms_key.main.arn
  recovery_window_in_days = 0

  tags = {
    Name = "${local.name_prefix}-db-credentials"
  }
}

resource "aws_secretsmanager_secret" "jwt_secret" {
  # checkov:skip=CKV2_AWS_57: "No implementaremos lambda de rotacion para la demo."
  name                    = "${var.project_name}/jwt-secret"
  description             = "Secreto JWT para autenticación del backend"
  kms_key_id              = aws_kms_key.main.arn
  recovery_window_in_days = 0

  tags = {
    Name = "${local.name_prefix}-jwt-secret"
  }
}
