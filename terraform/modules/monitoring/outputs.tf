# ──────────────────────────────────────────────
# Outputs — Módulo Monitoring
# ──────────────────────────────────────────────
# Estos valores se exponen al root module para que
# otros módulos puedan suscribirse al topic de alertas.
# ──────────────────────────────────────────────

output "sns_topic_arn" {
  description = "ARN del SNS Topic de alertas"
  value       = aws_sns_topic.alerts.arn
}

output "sns_topic_name" {
  description = "Nombre del SNS Topic de alertas"
  value       = aws_sns_topic.alerts.name
}
