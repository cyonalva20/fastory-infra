# ──────────────────────────────────────────────
# Módulo Database — Fastory
# ──────────────────────────────────────────────
# Recursos: RDS PostgreSQL, RDS Proxy, Secrets Manager
# para las credenciales y IAM Role para el proxy.
# ──────────────────────────────────────────────

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ════════════════════════════════════════════════
# DB SUBNET GROUP
# ════════════════════════════════════════════════

resource "aws_db_subnet_group" "main" {
  name        = "${local.name_prefix}-db-subnet-group"
  subnet_ids  = var.private_subnet_ids
  description = "Grupo de subredes para RDS PostgreSQL"

  tags = {
    Name = "${local.name_prefix}-db-subnet-group"
  }
}

# ════════════════════════════════════════════════
# RANDOM PASSWORD — Contraseña de la BD
# ════════════════════════════════════════════════

resource "random_password" "db_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# ════════════════════════════════════════════════
# SECRETS MANAGER — Credenciales de RDS para el Proxy
# ════════════════════════════════════════════════

resource "aws_secretsmanager_secret" "rds_credentials" {
  name        = "${local.name_prefix}/rds-proxy-credentials"
  description = "Credenciales de la BD PostgreSQL para RDS Proxy"
  kms_key_id  = var.kms_key_arn
  recovery_window_in_days = 0

  tags = {
    Name = "${local.name_prefix}-rds-proxy-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id

  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    engine   = "postgres"
    host     = aws_db_instance.main.address
    port     = var.db_port
    dbname   = var.db_name
  })
}

# ════════════════════════════════════════════════
# RDS INSTANCE — PostgreSQL
# ════════════════════════════════════════════════

resource "aws_db_instance" "main" {
  identifier = "${local.name_prefix}-postgres"

  # Motor y versión
  engine         = "postgres"
  engine_version = "16.4"
  instance_class = "db.t3.micro"

  # Almacenamiento
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = var.kms_key_arn

  # Credenciales
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result
  port     = var.db_port

  # Red
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_security_group_id]
  multi_az               = false
  publicly_accessible    = false

  # Backups y mantenimiento
  backup_retention_period         = 7
  skip_final_snapshot             = true
  auto_minor_version_upgrade      = true
  copy_tags_to_snapshot           = true
  deletion_protection             = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # Monitoreo
  performance_insights_enabled = false

  tags = {
    Name   = "${local.name_prefix}-postgres"
    Backup = "True"
  }
}

# ════════════════════════════════════════════════
# IAM ROLE — Para RDS Proxy
# ════════════════════════════════════════════════

resource "aws_iam_role" "rds_proxy" {
  name = "${local.name_prefix}-rds-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-rds-proxy-role"
  }
}

resource "aws_iam_role_policy" "rds_proxy" {
  name = "${local.name_prefix}-rds-proxy-policy"
  role = aws_iam_role.rds_proxy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSecretsAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [aws_secretsmanager_secret.rds_credentials.arn]
      },
      {
        Sid    = "AllowKMSDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = [var.kms_key_arn]
      }
    ]
  })
}

# ════════════════════════════════════════════════
# RDS PROXY
# ════════════════════════════════════════════════

resource "aws_db_proxy" "main" {
  name                   = "${local.name_prefix}-rds-proxy"
  debug_logging          = false
  engine_family          = "POSTGRESQL"
  idle_client_timeout    = 1800
  require_tls            = true
  role_arn               = aws_iam_role.rds_proxy.arn
  vpc_security_group_ids = [var.rds_security_group_id]
  vpc_subnet_ids         = var.private_subnet_ids

  auth {
    auth_scheme = "SECRETS"
    description = "Credenciales de la BD desde Secrets Manager"
    iam_auth    = "DISABLED"
    secret_arn  = aws_secretsmanager_secret.rds_credentials.arn
  }

  tags = {
    Name = "${local.name_prefix}-rds-proxy"
  }
}

resource "aws_db_proxy_default_target_group" "main" {
  db_proxy_name = aws_db_proxy.main.name

  connection_pool_config {
    max_connections_percent      = 100
    max_idle_connections_percent = 50
    connection_borrow_timeout    = 120
  }
}

resource "aws_db_proxy_target" "main" {
  db_proxy_name          = aws_db_proxy.main.name
  target_group_name      = aws_db_proxy_default_target_group.main.name
  db_instance_identifier = aws_db_instance.main.identifier
}
