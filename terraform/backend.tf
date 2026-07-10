# ──────────────────────────────────────────────
# Backend remoto — S3 + DynamoDB para state locking
# ──────────────────────────────────────────────
# Con Terraform Workspaces, el state se almacena
# automáticamente en:
#   env:/dev/fastory/terraform.tfstate
#   env:/prod/fastory/terraform.tfstate
# ──────────────────────────────────────────────

terraform {
  backend "s3" {
    bucket         = "fastory-terraform-state-099090990554"
    key            = "fastory/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "fastory-terraform-locks"
  }
}
