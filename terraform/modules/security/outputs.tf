# ──────────────────────────────────────────────
# Outputs — Módulo Security
# ──────────────────────────────────────────────
# Estos valores se exponen al root module para que
# otros módulos (compute, database, etc.) puedan referenciarlos.
# ──────────────────────────────────────────────

# ── Security Groups ──────────────────────────

output "alb_security_group_id" {
  description = "ID del Security Group del ALB"
  value       = aws_security_group.alb.id
}

output "ec2_security_group_id" {
  description = "ID del Security Group de las instancias EC2"
  value       = aws_security_group.ec2.id
}

output "rds_security_group_id" {
  description = "ID del Security Group de RDS"
  value       = aws_security_group.rds.id
}

output "redis_security_group_id" {
  description = "ID del Security Group de ElastiCache Redis"
  value       = aws_security_group.redis.id
}

# ── KMS ──────────────────────────────────────

output "kms_key_id" {
  description = "ID de la llave KMS"
  value       = aws_kms_key.main.key_id
}

output "kms_key_arn" {
  description = "ARN de la llave KMS"
  value       = aws_kms_key.main.arn
}

# ── Secrets Manager ──────────────────────────

output "db_credentials_secret_arn" {
  description = "ARN del secreto de credenciales de la BD"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "jwt_secret_arn" {
  description = "ARN del secreto JWT"
  value       = aws_secretsmanager_secret.jwt_secret.arn
}
