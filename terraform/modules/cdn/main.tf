# ──────────────────────────────────────────────
# Módulo CDN — Fastory
# ──────────────────────────────────────────────
# Recursos: CloudFront Distribution (CDN global),
# ACM Certificate (SSL/TLS) y WAFv2 Web ACL.
# ACM y WAF se crean SOLO si enable_custom_domain = true
# para evitar costos innecesarios en entornos de prueba.
# ──────────────────────────────────────────────

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ════════════════════════════════════════════════
# 1. ACM CERTIFICATE — Certificado SSL/TLS
# ════════════════════════════════════════════════
# Se crea SOLO con dominio personalizado habilitado.
# Requiere validación DNS (Route 53) para activarse.

resource "aws_acm_certificate" "main" {
  count = var.enable_custom_domain ? 1 : 0

  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${local.name_prefix}-acm-cert"
  }
}

# ════════════════════════════════════════════════
# 2. WAFv2 WEB ACL — Firewall de Aplicación Web
# ════════════════════════════════════════════════
# Se crea SOLO con dominio personalizado habilitado.
# Incluye reglas base de AWS para protección contra
# ataques comunes (SQL injection, XSS, etc.).
# NOTA: SCOPE=CLOUDFRONT requiere región us-east-1.

resource "aws_wafv2_web_acl" "main" {
  count = var.enable_custom_domain ? 1 : 0

  name  = "${local.name_prefix}-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # Regla: AWS Managed Rules — Conjunto de reglas base
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-waf-common-rules"
      sampled_requests_enabled   = true
    }
  }

  # Regla: AWS Managed Rules — Protección contra SQL Injection
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-waf-sqli-rules"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name_prefix}-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "${local.name_prefix}-waf"
  }
}

# ════════════════════════════════════════════════
# 3. CLOUDFRONT — Origin Access Control (OAC)
# ════════════════════════════════════════════════
# Permite que CloudFront acceda al bucket S3 privado.

resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "${local.name_prefix}-s3-oac"
  description                       = "OAC para acceso de CloudFront al bucket S3 del frontend"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ════════════════════════════════════════════════
# 4. CLOUDFRONT DISTRIBUTION — CDN Global
# ════════════════════════════════════════════════
# Distribuye el contenido del frontend desde edge locations
# globales de AWS, reduciendo la latencia para los usuarios.

resource "aws_cloudfront_distribution" "main" {
  comment             = "CDN para ${local.name_prefix} — Frontend y API"
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  # ── Dominio personalizado (solo si está habilitado) ──
  aliases = var.enable_custom_domain ? [var.domain_name, "www.${var.domain_name}"] : []

  # ── WAF (solo si está habilitado) ──
  web_acl_id = var.enable_custom_domain ? aws_wafv2_web_acl.main[0].arn : null

  # ── Origen 1: S3 Frontend (contenido estático) ──
  origin {
    domain_name              = var.s3_frontend_bucket_domain_name
    origin_id                = "s3-frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
  }

  # ── Origen 2: ALB Backend (API) ──
  origin {
    domain_name = var.alb_dns_name
    origin_id   = "alb-api"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # ── Comportamiento por defecto: S3 Frontend ──
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-frontend"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # ── Comportamiento para la API: ALB Backend ──
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "alb-api"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Origin", "Accept"]
      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  # ── SSL/TLS ──
  viewer_certificate {
    # Si hay dominio personalizado, usa el certificado ACM
    # Si no, usa el certificado por defecto de CloudFront
    cloudfront_default_certificate = var.enable_custom_domain ? false : true
    acm_certificate_arn            = var.enable_custom_domain ? aws_acm_certificate.main[0].arn : null
    ssl_support_method             = var.enable_custom_domain ? "sni-only" : null
    minimum_protocol_version       = var.enable_custom_domain ? "TLSv1.2_2021" : null
  }

  # ── Restricciones geográficas (sin restricción) ──
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # ── Página de error personalizada (SPA routing) ──
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  tags = {
    Name = "${local.name_prefix}-cdn"
  }
}

# ════════════════════════════════════════════════
# 5. S3 BUCKET POLICY — Acceso desde CloudFront
# ════════════════════════════════════════════════
# Permite que CloudFront (via OAC) lea los objetos del bucket S3.

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = var.s3_frontend_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::${var.s3_frontend_bucket_id}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.main.arn
          }
        }
      }
    ]
  })
}
