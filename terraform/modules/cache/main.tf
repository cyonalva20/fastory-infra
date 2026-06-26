# ──────────────────────────────────────────────
# Módulo Cache — Fastory
# ──────────────────────────────────────────────
# Recursos de caché del proyecto.
# Incluye: ElastiCache Subnet Group y Cluster Redis
# de un solo nodo para sesiones y caché de aplicación.
# ──────────────────────────────────────────────

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ════════════════════════════════════════════════
# 1. ELASTICACHE SUBNET GROUP
# ════════════════════════════════════════════════
# Grupo de subredes privadas donde se despliega Redis.
# Garantiza que el nodo viva en la red interna.

resource "aws_elasticache_subnet_group" "main" {
  name       = "${local.name_prefix}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${local.name_prefix}-redis-subnet-group"
  }
}

# ════════════════════════════════════════════════
# 2. ELASTICACHE CLUSTER (Redis)
# ════════════════════════════════════════════════
# Cluster Redis de un solo nodo (cache.t3.micro).
# Se usa para caché de aplicación y manejo de sesiones.

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${local.name_prefix}-redis"
  engine               = "redis"
  node_type            = var.redis_node_type
  num_cache_nodes      = 1
  port                 = var.redis_port
  parameter_group_name = "default.redis7"
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids       = [var.redis_security_group_id]
  snapshot_retention_limit = 7

  tags = {
    Name = "${local.name_prefix}-redis"
  }
}
