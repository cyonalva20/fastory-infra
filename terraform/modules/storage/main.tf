# ──────────────────────────────────────────────
# Módulo Storage — Fastory
# ──────────────────────────────────────────────
# Recursos: S3 Bucket para alojar el frontend estático
# (React/Angular/Vue) con configuración de website hosting.
# ──────────────────────────────────────────────

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ════════════════════════════════════════════════
# 1. S3 BUCKET — Frontend estático
# ════════════════════════════════════════════════
# Almacena los archivos compilados del frontend (HTML, CSS, JS).

resource "aws_s3_bucket" "frontend" {
  bucket = "${local.name_prefix}-frontend"

  tags = {
    Name = "${local.name_prefix}-frontend"
  }
}

# ════════════════════════════════════════════════
# 2. VERSIONAMIENTO — Historial de versiones
# ════════════════════════════════════════════════
# Permite recuperar versiones anteriores del frontend.

resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ════════════════════════════════════════════════
# 3. CIFRADO — Server-Side Encryption
# ════════════════════════════════════════════════
# Cifrado automático de todos los objetos con AES-256.

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ════════════════════════════════════════════════
# 4. BLOQUEO DE ACCESO PÚBLICO — Seguridad
# ════════════════════════════════════════════════
# El acceso público se controla SOLO a través de CloudFront (OAC).
# El bucket en sí permanece privado.

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ════════════════════════════════════════════════
# 5. WEBSITE CONFIGURATION — Hosting estático
# ════════════════════════════════════════════════
# Configura el bucket como sitio web estático.

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}
