# ──────────────────────────────────────────────
# Outputs — Módulo Storage
# ──────────────────────────────────────────────

output "frontend_bucket_id" {
  description = "ID del bucket S3 del frontend"
  value       = aws_s3_bucket.frontend.id
}

output "frontend_bucket_arn" {
  description = "ARN del bucket S3 del frontend"
  value       = aws_s3_bucket.frontend.arn
}

output "frontend_bucket_domain_name" {
  description = "Nombre de dominio del bucket S3 (para CloudFront)"
  value       = aws_s3_bucket.frontend.bucket_regional_domain_name
}

output "frontend_website_endpoint" {
  description = "Endpoint del sitio web estático del frontend"
  value       = aws_s3_bucket_website_configuration.frontend.website_endpoint
}
