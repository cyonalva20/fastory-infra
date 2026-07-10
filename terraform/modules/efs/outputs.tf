output "file_system_id" {
  value = aws_efs_file_system.main.id
}

output "grafana_access_point_id" {
  value = aws_efs_access_point.grafana.id
}

output "loki_access_point_id" {
  value = aws_efs_access_point.loki.id
}
