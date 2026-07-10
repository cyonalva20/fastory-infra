output "cluster_id" {
  value = aws_ecs_cluster.main.id
}

output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "service_name" {
  value = aws_ecs_service.backend.name
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "alb_listener_arn" {
  value = aws_lb_listener.http.arn
}

output "cloudmap_namespace_id" {
  value = aws_service_discovery_private_dns_namespace.main.id
}
