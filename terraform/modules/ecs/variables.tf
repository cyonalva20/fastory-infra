variable "project_name" { type = string }
variable "environment" { type = string }

variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }

variable "alb_security_group_id" { type = string }
variable "ecs_security_group_id" { type = string }

variable "backend_repository_url" { type = string }
variable "backend_cpu" { type = number }
variable "backend_memory" { type = number }
variable "backend_desired_count" { type = number }
variable "use_fargate_spot" { type = bool }

variable "db_credentials_secret_arn" { type = string }
variable "jwt_secret_arn" { type = string }
variable "kms_key_arn" { type = string }
