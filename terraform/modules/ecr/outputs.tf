output "backend_repository_url" {
  value = aws_ecr_repository.repos["backend"].repository_url
}

output "grafana_repository_url" {
  value = aws_ecr_repository.repos["grafana"].repository_url
}

output "prometheus_repository_url" {
  value = aws_ecr_repository.repos["prometheus"].repository_url
}

output "loki_repository_url" {
  value = aws_ecr_repository.repos["loki"].repository_url
}
