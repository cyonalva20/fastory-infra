# ──────────────────────────────────────────────
# Módulo Messaging — Fastory
# ──────────────────────────────────────────────
# Recursos: SQS Queue principal, Dead Letter Queue (DLQ)
# y política de redrive para mensajes fallidos.
# ──────────────────────────────────────────────

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ════════════════════════════════════════════════
# SQS DLQ — Cola de mensajes fallidos
# ════════════════════════════════════════════════
# Los mensajes que fallan repetidamente se envían aquí para análisis.

resource "aws_sqs_queue" "dlq" {
  name                              = "${local.name_prefix}-dlq"
  message_retention_seconds         = 1209600 # 14 días
  kms_master_key_id                 = var.kms_key_arn
  kms_data_key_reuse_period_seconds = 300

  tags = {
    Name = "${local.name_prefix}-dlq"
  }
}

# ════════════════════════════════════════════════
# SQS QUEUE — Cola principal
# ════════════════════════════════════════════════
# Cola principal de mensajes para procesamiento asíncrono.

resource "aws_sqs_queue" "main" {
  name                       = "${local.name_prefix}-queue"
  delay_seconds              = 0
  max_message_size           = 262144  # 256 KB
  message_retention_seconds  = 345600  # 4 días
  receive_wait_time_seconds  = 10      # Long polling
  visibility_timeout_seconds = 30
  kms_master_key_id          = var.kms_key_arn
  kms_data_key_reuse_period_seconds = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name = "${local.name_prefix}-queue"
  }
}

# ════════════════════════════════════════════════
# SQS REDRIVE ALLOW POLICY — Permisos de redrive
# ════════════════════════════════════════════════
# Permite que solo la cola principal envíe mensajes a la DLQ.

resource "aws_sqs_queue_redrive_allow_policy" "dlq" {
  queue_url = aws_sqs_queue.dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.main.arn]
  })
}
