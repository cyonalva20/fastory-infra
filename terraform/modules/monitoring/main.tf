locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ════════════════════════════════════════════════
# ALARMA: CPU Alta — Escalar hacia arriba (Scale Out)
# ════════════════════════════════════════════════
# Cuando el uso de CPU promedio supera el 80% durante 2 periodos
# consecutivos de 120s, se dispara la alarma y se notifica.

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${local.name_prefix}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alarma si el uso de CPU de Fargate supera el 80%. El Auto Scaling se encarga de escalar automaticamente."

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = var.autoscaling_scale_up_arn != "" ? [var.autoscaling_scale_up_arn] : []
}

# ════════════════════════════════════════════════
# ALARMA: CPU Baja — Escalar hacia abajo (Scale In)
# ════════════════════════════════════════════════
# Cuando el uso de CPU promedio baja del 30% durante 3 periodos
# consecutivos de 120s, se notifica para reducir contenedores.

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_low" {
  alarm_name          = "${local.name_prefix}-ecs-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "Alarma si el uso de CPU de Fargate baja del 30%. Indica que hay recursos sobredimensionados."

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }
}

# ════════════════════════════════════════════════
# ALARMA: Memoria Alta
# ════════════════════════════════════════════════
# Cuando el uso de Memoria promedio supera el 80% durante 2 periodos.

resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "${local.name_prefix}-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alarma si el uso de Memoria de Fargate supera el 80%. El Auto Scaling de memoria se encarga de escalar."

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = var.autoscaling_scale_up_arn != "" ? [var.autoscaling_scale_up_arn] : []
}

# ════════════════════════════════════════════════
# ALARMA: Errores 5XX en el Load Balancer
# ════════════════════════════════════════════════
# Más de 10 errores 5XX en 1 minuto indica problemas graves
# en el backend (caída de base de datos, errores de código, etc.)

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${local.name_prefix}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alarma si hay mas de 10 errores 5XX en 1 minuto"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}

# ════════════════════════════════════════════════
# ALARMA: Latencia Alta en el ALB
# ════════════════════════════════════════════════
# Cuando el tiempo de respuesta promedio del backend supera 2 segundos.

resource "aws_cloudwatch_metric_alarm" "alb_high_latency" {
  alarm_name          = "${local.name_prefix}-alb-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "2"
  alarm_description   = "Alarma si la latencia promedio del backend supera 2 segundos"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}
