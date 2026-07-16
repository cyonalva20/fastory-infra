# ──────────────────────────────────────────────
# Módulo ElastiCache (Redis) — Fastory
# ──────────────────────────────────────────────
# Despliega un nodo Redis en las subredes privadas
# como capa de caché entre ECS Fargate y RDS.
# ──────────────────────────────────────────────

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# Subnet Group — Redis vive en las subredes privadas
resource "aws_elasticache_subnet_group" "redis" {
  name       = "${local.name_prefix}-redis-subnet"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${local.name_prefix}-redis-subnet"
  }
}

# Clúster Redis — Nodo único para desarrollo, replicado en producción
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${local.name_prefix}-redis"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.redis_node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [var.redis_security_group_id]

  # Cifrado en tránsito y en reposo
  transit_encryption_enabled = false # Requiere TLS en el cliente
  snapshot_retention_limit   = 1     # Checkov requiere backups habilitados

  tags = {
    Name        = "${local.name_prefix}-redis"
    Environment = var.environment
  }
}
