variable "project_name" { type = string }
variable "environment" { type = string }
variable "ecs_cluster_name" { type = string }
variable "ecs_service_name" { type = string }
variable "alb_arn_suffix" { type = string }

variable "autoscaling_scale_up_arn" {
  description = "ARN de la política de Auto Scaling para escalar hacia arriba (CPU)"
  type        = string
  default     = ""
}
