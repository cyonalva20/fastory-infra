variable "project_name" { type = string }
variable "environment" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "redis_security_group_id" { type = string }

variable "redis_node_type" {
  description = "Tipo de instancia del nodo Redis"
  type        = string
  default     = "cache.t3.micro"
}
