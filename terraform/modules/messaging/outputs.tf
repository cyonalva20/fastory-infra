# ──────────────────────────────────────────────
# Outputs — Módulo Messaging
# ──────────────────────────────────────────────
# Estos valores se exponen al root module para que
# otros módulos (compute, etc.) puedan referenciarlos.
# ──────────────────────────────────────────────

# ── SQS ──────────────────────────────────────

output "queue_url" {
  description = "URL de la cola SQS principal"
  value       = aws_sqs_queue.main.url
}

output "queue_arn" {
  description = "ARN de la cola SQS principal"
  value       = aws_sqs_queue.main.arn
}

output "dlq_url" {
  description = "URL de la Dead Letter Queue"
  value       = aws_sqs_queue.dlq.url
}

output "dlq_arn" {
  description = "ARN de la Dead Letter Queue"
  value       = aws_sqs_queue.dlq.arn
}
