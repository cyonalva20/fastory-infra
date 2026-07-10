variable "project_name" { type = string }
variable "environment" { type = string }

variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "observability_security_group_id" { type = string }

variable "ecs_cluster_id" { type = string }
variable "cloudmap_namespace_id" { type = string }

variable "efs_file_system_id" { type = string }
variable "efs_grafana_access_point_id" { type = string }
variable "efs_loki_access_point_id" { type = string }

variable "grafana_repository_url" { type = string }
variable "prometheus_repository_url" { type = string }
variable "loki_repository_url" { type = string }

variable "alb_listener_arn" { type = string }
