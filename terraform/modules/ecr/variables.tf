variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Entorno (dev, prod)"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN de la llave KMS para cifrar los repositorios"
  type        = string
}
