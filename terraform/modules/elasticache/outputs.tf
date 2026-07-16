output "redis_endpoint" {
  description = "Endpoint de conexión del clúster Redis"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "redis_port" {
  description = "Puerto de conexión de Redis"
  value       = aws_elasticache_cluster.redis.port
}
