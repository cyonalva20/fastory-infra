# ──────────────────────────────────────────────
# Outputs — Módulo Cache
# ──────────────────────────────────────────────
# Estos valores se exponen al root module para que
# la aplicación pueda conectarse al cluster Redis.
# ──────────────────────────────────────────────

output "redis_endpoint" {
  description = "Endpoint de conexión del cluster Redis"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "redis_port" {
  description = "Puerto de conexión del cluster Redis"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].port
}
