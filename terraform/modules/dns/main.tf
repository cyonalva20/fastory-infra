# ──────────────────────────────────────────────
# Módulo DNS — Fastory
# ──────────────────────────────────────────────
# Recursos: Route 53 Hosted Zone y registros DNS.
# Se crean SOLO si enable_custom_domain = true para
# evitar costos de hosted zone ($0.50/mes) en pruebas.
# ──────────────────────────────────────────────

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ════════════════════════════════════════════════
# 1. HOSTED ZONE — Zona DNS
# ════════════════════════════════════════════════
# Zona donde se gestionan los registros DNS del dominio.

resource "aws_route53_zone" "main" {
  count = var.enable_custom_domain ? 1 : 0

  name    = var.domain_name
  comment = "Zona DNS para ${local.name_prefix}"

  tags = {
    Name = "${local.name_prefix}-dns-zone"
  }
}

# ════════════════════════════════════════════════
# 2. REGISTRO A — Dominio raíz → CloudFront
# ════════════════════════════════════════════════
# Apunta fastory.com al CDN de CloudFront.

resource "aws_route53_record" "root" {
  count = var.enable_custom_domain ? 1 : 0

  zone_id = aws_route53_zone.main[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = "Z2FDTNDATAQYW2" # ID fija de CloudFront en Route 53
    evaluate_target_health = false
  }
}

# ════════════════════════════════════════════════
# 3. REGISTRO A — www → CloudFront
# ════════════════════════════════════════════════
# Apunta www.fastory.com al mismo CDN de CloudFront.

resource "aws_route53_record" "www" {
  count = var.enable_custom_domain ? 1 : 0

  zone_id = aws_route53_zone.main[0].zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

# ════════════════════════════════════════════════
# 4. REGISTRO A — API → CloudFront
# ════════════════════════════════════════════════
# Apunta api.fastory.com al CDN (que redirige /api/* al ALB).

resource "aws_route53_record" "api" {
  count = var.enable_custom_domain ? 1 : 0

  zone_id = aws_route53_zone.main[0].zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}
