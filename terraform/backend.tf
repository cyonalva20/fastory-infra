# ──────────────────────────────────────────────
# Backend remoto — S3 + DynamoDB para state locking
# ──────────────────────────────────────────────

terraform {
  backend "s3" {
    bucket         = "fastory-terraform-state-099090990554"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "fastory-terraform-locks"
  }
}
