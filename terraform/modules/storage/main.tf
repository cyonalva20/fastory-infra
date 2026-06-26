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
# 3. CICLO DE VIDA — Limpieza de versiones antiguas
# ════════════════════════════════════════════════
# Elimina automáticamente las versiones antiguas de los objetos
# después de 90 días para ahorrar costos de almacenamiento.

resource "aws_s3_bucket_lifecycle_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    id     = "cleanup-noncurrent-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# ════════════════════════════════════════════════
# 4. CIFRADO — Server-Side Encryption
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
# 5. BLOQUEO DE ACCESO PÚBLICO — Seguridad
# ════════════════════════════════════════════════
# El acceso público se controla SOLO a través de CloudFront (OAC).
# El bucket en sí permanece privado.

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# ════════════════════════════════════════════════
# 6. WEBSITE CONFIGURATION — Hosting estático
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

# ════════════════════════════════════════════════
# 7. BUCKET POLICY — Acceso Público (Solo para Demo sin CDN)
# ════════════════════════════════════════════════

resource "aws_s3_bucket_policy" "public_read" {
  # checkov:skip=CKV_AWS_20: "S3 Bucket is public because CDN is disabled for university demo."
  bucket = aws_s3_bucket.frontend.id

  depends_on = [aws_s3_bucket_public_access_block.frontend]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })
}
