# ──────────────────────────────────────────────
# Outputs — Módulo Compute
# ──────────────────────────────────────────────
# Estos valores se exponen al root module para que
# otros módulos (monitoring, etc.) puedan referenciarlos.
# ──────────────────────────────────────────────

# ── ALB ──────────────────────────────────────

output "alb_dns_name" {
  description = "Nombre DNS público del Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn_suffix" {
  description = "Sufijo del ARN del ALB (para métricas de CloudWatch)"
  value       = aws_lb.main.arn_suffix
}

# ── Target Group ─────────────────────────────

output "target_group_arn" {
  description = "ARN del Target Group"
  value       = aws_lb_target_group.main.arn
}

output "target_group_arn_suffix" {
  description = "Sufijo del ARN del Target Group (para métricas de CloudWatch)"
  value       = aws_lb_target_group.main.arn_suffix
}

# ── Auto Scaling Group ───────────────────────

output "asg_name" {
  description = "Nombre del Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

# ── IAM ──────────────────────────────────────

output "ec2_role_arn" {
  description = "ARN del IAM Role de las instancias EC2"
  value       = aws_iam_role.ec2.arn
}
