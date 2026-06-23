# ──────────────────────────────────────────────
# Módulo Monitoring — Fastory
# ──────────────────────────────────────────────
# Recursos de monitoreo y alertas del proyecto.
# Incluye: SNS Topic para notificaciones y alarmas
# de CloudWatch para CPU del ASG y hosts no saludables
# del ALB.
# ──────────────────────────────────────────────

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ════════════════════════════════════════════════
# 1. SNS TOPIC PARA ALERTAS
# ════════════════════════════════════════════════
# Topic central donde se envían todas las alarmas.
# Se pueden suscribir emails, webhooks, Lambda, etc.

resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"

  tags = {
    Name = "${local.name_prefix}-alerts"
  }
}

# ════════════════════════════════════════════════
# 2. ALARMA — CPU Utilization del ASG > 80%
# ════════════════════════════════════════════════
# Monitorea el uso promedio de CPU de las instancias
# en el Auto Scaling Group. Se activa cuando supera
# el 80% durante 2 periodos consecutivos de 5 minutos.

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${local.name_prefix}-cpu-high"
  alarm_description   = "Alarma: CPU del ASG supera el 80% de utilización"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  # Enviar notificación al SNS topic cuando la alarma se activa
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${local.name_prefix}-cpu-high"
  }
}

# ════════════════════════════════════════════════
# 3. ALARMA — UnHealthyHostCount del ALB >= 1
# ════════════════════════════════════════════════
# Monitorea la cantidad de hosts no saludables en el
# Target Group del ALB. Se activa cuando al menos 1
# host falla el health check durante 2 periodos de 1 minuto.

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${local.name_prefix}-unhealthy-hosts"
  alarm_description   = "Alarma: Hay hosts no saludables en el Target Group del ALB"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    TargetGroup  = var.target_group_arn_suffix
    LoadBalancer = var.alb_arn_suffix
  }

  # Enviar notificación al SNS topic cuando la alarma se activa
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${local.name_prefix}-unhealthy-hosts"
  }
}
