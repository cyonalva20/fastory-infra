# ──────────────────────────────────────────────
# Módulo ECS Core — Fastory
# ──────────────────────────────────────────────
# Incluye: ALB, ECS Cluster, Service Discovery,
# IAM Roles, Task Definition (Backend + FireLens)
# y ECS Service.
# ──────────────────────────────────────────────

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ════════════════════════════════════════════════
# 1. APPLICATION LOAD BALANCER
# ════════════════════════════════════════════════

resource "aws_lb" "main" {
  # checkov:skip=CKV_AWS_150: "Deletion protection disabled for academic demo environment"
  # checkov:skip=CKV_AWS_91: "Access logging requires dedicated S3 bucket, out of scope for demo"
  # checkov:skip=CKV2_AWS_28: "WAF is cost-prohibitive for academic project"
  # checkov:skip=CKV2_AWS_20: "No ACM certificate available for HTTPS redirect in demo"
  name                       = "${local.name_prefix}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.alb_security_group_id]
  subnets                    = var.public_subnet_ids
  enable_deletion_protection = false
  drop_invalid_header_fields = true

  tags = { Name = "${local.name_prefix}-alb" }
}

resource "aws_lb_target_group" "backend" {
  # checkov:skip=CKV_AWS_378: "Internal ALB-to-Fargate traffic uses HTTP, no TLS termination needed"
  name        = "${local.name_prefix}-backend-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip" # Requerido para awsvpc (Fargate)

  health_check {
    path                = "/actuator/health"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_listener" "http" {
  # checkov:skip=CKV_AWS_2: "No ACM certificate for HTTPS in academic demo"
  # checkov:skip=CKV_AWS_103: "TLS not applicable without ACM certificate"
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

# ════════════════════════════════════════════════
# 2. ECS CLUSTER & CLOUD MAP (Service Discovery)
# ════════════════════════════════════════════════

resource "aws_ecs_cluster" "main" {
  name = local.name_prefix

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 0
    weight            = 1
    capacity_provider = var.use_fargate_spot ? "FARGATE_SPOT" : "FARGATE"
  }
}

resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "fastory.local"
  description = "Service discovery para Fastory ECS Cluster"
  vpc         = var.vpc_id
}

# ════════════════════════════════════════════════
# 3. IAM ROLES PARA ECS
# ════════════════════════════════════════════════

# ── Task Execution Role (permisos para arrancar la tarea) ──
resource "aws_iam_role" "execution" {
  name = "${local.name_prefix}-ecs-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_exec" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_exec_secrets" {
  name = "${local.name_prefix}-ecs-exec-secrets"
  role = aws_iam_role.execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = [
          var.db_credentials_secret_arn,
          var.jwt_secret_arn
        ]
      },
      {
        Effect = "Allow"
        Action = ["kms:Decrypt"]
        Resource = [
          var.kms_key_arn
        ]
      }
    ]
  })
}

# ── Task Role (permisos de la aplicación en ejecución) ──
resource "aws_iam_role" "task" {
  name = "${local.name_prefix}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# ════════════════════════════════════════════════
# 4. TASK DEFINITION (Backend + FireLens)
# ════════════════════════════════════════════════

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${local.name_prefix}-backend"
  retention_in_days = 365
  kms_key_id        = var.kms_key_arn
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "${local.name_prefix}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.backend_cpu
  memory                   = var.backend_memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name                   = "log_router"
      image                  = "public.ecr.aws/aws-observability/aws-for-fluent-bit:latest"
      essential              = true
      readonlyRootFilesystem = true
      firelensConfiguration = {
        type = "fluentbit"
        options = {
          enable-ecs-log-metadata = "true"
        }
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "firelens"
        }
      }
      memoryReservation = 50
    },
    {
      name                   = "backend"
      image                  = "${var.backend_repository_url}:latest"
      essential              = true
      readonlyRootFilesystem = true
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      secrets = [
        {
          name      = "SPRING_DATASOURCE_PASSWORD"
          valueFrom = var.db_credentials_secret_arn
        },
        {
          name      = "JWT_SECRET"
          valueFrom = var.jwt_secret_arn
        }
      ]
      logConfiguration = {
        logDriver = "awsfirelens"
        options = {
          Name         = "http"
          Host         = "loki.fastory.local"
          Port         = "3100"
          URI          = "/loki/api/v1/push"
          Format       = "json"
          tls          = "off"
          "tls.verify" = "off"
          Retry_Limit  = "2"
        }
      }
    }
  ])
}

# ════════════════════════════════════════════════
# 5. ECS SERVICE (Backend)
# ════════════════════════════════════════════════

resource "aws_service_discovery_service" "backend" {
  name = "backend"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id
    dns_records {
      ttl  = 10
      type = "A"
    }
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_service" "backend" {
  name            = "${local.name_prefix}-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = var.backend_desired_count

  capacity_provider_strategy {
    capacity_provider = var.use_fargate_spot ? "FARGATE_SPOT" : "FARGATE"
    weight            = 1
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 8080
  }

  service_registries {
    registry_arn = aws_service_discovery_service.backend.arn
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count] # El CD pipeline y Auto Scaling actualizan esto
  }
}

# ════════════════════════════════════════════════
# AUTO SCALING — Escalado automático del Backend
# ════════════════════════════════════════════════
# Permite que ECS Fargate escale horizontalmente (más contenedores)
# cuando la carga de CPU supera el umbral definido.

resource "aws_appautoscaling_target" "backend" {
  max_capacity       = var.backend_max_capacity
  min_capacity       = var.backend_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.backend.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Política de escalado por CPU — Target Tracking
# Mantiene el uso promedio de CPU al 70%
resource "aws_appautoscaling_policy" "backend_cpu" {
  name               = "${local.name_prefix}-backend-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.backend.resource_id
  scalable_dimension = aws_appautoscaling_target.backend.scalable_dimension
  service_namespace  = aws_appautoscaling_target.backend.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Política de escalado por Memoria — Target Tracking
# Mantiene el uso promedio de Memoria al 75%
resource "aws_appautoscaling_policy" "backend_memory" {
  name               = "${local.name_prefix}-backend-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.backend.resource_id
  scalable_dimension = aws_appautoscaling_target.backend.scalable_dimension
  service_namespace  = aws_appautoscaling_target.backend.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 75.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
