# ──────────────────────────────────────────────
# Outputs — Módulo DNS
# ──────────────────────────────────────────────

output "hosted_zone_id" {
  description = "ID de la Hosted Zone de Route 53 (vacío si dominio no habilitado)"
  value       = var.enable_custom_domain ? aws_route53_zone.main[0].zone_id : ""
}

output "name_servers" {
  description = "Name servers de la Hosted Zone (vacío si dominio no habilitado)"
  value       = var.enable_custom_domain ? aws_route53_zone.main[0].name_servers : []
}
