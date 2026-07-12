# ──────────────────────────────────────────────
# Módulo Observability — Fastory
# ──────────────────────────────────────────────
# Prometheus, Loki y Grafana en ECS Fargate con
# persistencia en EFS y Service Discovery.
# ──────────────────────────────────────────────

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ════════════════════════════════════════════════
# 1. IAM ROLE PARA OBSERVABILIDAD
# ════════════════════════════════════════════════

resource "aws_iam_role" "obs_execution" {
  name = "${local.name_prefix}-obs-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "obs_exec" {
  role       = aws_iam_role.obs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "obs_task" {
  name = "${local.name_prefix}-obs-task-role"
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
# 2. PROMETHEUS
# ════════════════════════════════════════════════

resource "aws_cloudwatch_log_group" "prometheus" {
  name              = "/ecs/${local.name_prefix}-prometheus"
  retention_in_days = 365
  kms_key_id        = var.kms_key_arn
}

resource "aws_ecs_task_definition" "prometheus" {
  family                   = "${local.name_prefix}-prometheus"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.obs_execution.arn
  task_role_arn            = aws_iam_role.obs_task.arn

  container_definitions = jsonencode([{
    name                   = "prometheus"
    image                  = "${var.prometheus_repository_url}:latest"
    essential              = true
    readonlyRootFilesystem = true
    portMappings = [{
      containerPort = 9090
      protocol      = "tcp"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.prometheus.name
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_service_discovery_service" "prometheus" {
  name = "prometheus"
  dns_config {
    namespace_id = var.cloudmap_namespace_id
    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

resource "aws_ecs_service" "prometheus" {
  name            = "${local.name_prefix}-prometheus"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.prometheus.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.observability_security_group_id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.prometheus.arn
  }
}

# ════════════════════════════════════════════════
# 3. LOKI (CON EFS)
# ════════════════════════════════════════════════

resource "aws_cloudwatch_log_group" "loki" {
  name              = "/ecs/${local.name_prefix}-loki"
  retention_in_days = 365
  kms_key_id        = var.kms_key_arn
}

resource "aws_ecs_task_definition" "loki" {
  family                   = "${local.name_prefix}-loki"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.obs_execution.arn
  task_role_arn            = aws_iam_role.obs_task.arn

  volume {
    name = "loki-data"
    efs_volume_configuration {
      file_system_id     = var.efs_file_system_id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = var.efs_loki_access_point_id
        iam             = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([{
    name                   = "loki"
    image                  = "${var.loki_repository_url}:latest"
    essential              = true
    readonlyRootFilesystem = true
    portMappings = [{
      containerPort = 3100
      protocol      = "tcp"
    }]
    mountPoints = [{
      sourceVolume  = "loki-data"
      containerPath = "/loki"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.loki.name
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_service_discovery_service" "loki" {
  name = "loki"
  dns_config {
    namespace_id = var.cloudmap_namespace_id
    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

resource "aws_ecs_service" "loki" {
  name            = "${local.name_prefix}-loki"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.loki.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.observability_security_group_id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.loki.arn
  }
}

# ════════════════════════════════════════════════
# 4. GRAFANA (CON EFS Y ALB)
# ════════════════════════════════════════════════

resource "aws_cloudwatch_log_group" "grafana" {
  name              = "/ecs/${local.name_prefix}-grafana"
  retention_in_days = 365
  kms_key_id        = var.kms_key_arn
}

resource "aws_lb_target_group" "grafana" {
  # checkov:skip=CKV_AWS_378: "Internal ALB-to-Fargate traffic uses HTTP, no TLS termination needed"
  name        = "${local.name_prefix}-grafana-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/api/health"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_listener_rule" "grafana" {
  listener_arn = var.alb_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }

  condition {
    path_pattern {
      values = ["/grafana", "/grafana/*"]
    }
  }
}

resource "aws_ecs_task_definition" "grafana" {
  family                   = "${local.name_prefix}-grafana"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.obs_execution.arn
  task_role_arn            = aws_iam_role.obs_task.arn

  volume {
    name = "grafana-data"
    efs_volume_configuration {
      file_system_id     = var.efs_file_system_id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = var.efs_grafana_access_point_id
        iam             = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([{
    name                   = "grafana"
    image                  = "${var.grafana_repository_url}:latest"
    essential              = true
    readonlyRootFilesystem = true
    environment = [
      { name = "GF_SERVER_ROOT_URL", value = "%(protocol)s://%(domain)s:%(http_port)s/grafana/" },
      { name = "GF_SERVER_SERVE_FROM_SUB_PATH", value = "true" }
    ]
    portMappings = [{
      containerPort = 3000
      protocol      = "tcp"
    }]
    mountPoints = [{
      sourceVolume  = "grafana-data"
      containerPath = "/var/lib/grafana"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.grafana.name
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_service_discovery_service" "grafana" {
  name = "grafana"
  dns_config {
    namespace_id = var.cloudmap_namespace_id
    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

resource "aws_ecs_service" "grafana" {
  name            = "${local.name_prefix}-grafana"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.grafana.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.observability_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.grafana.arn
    container_name   = "grafana"
    container_port   = 3000
  }

  service_registries {
    registry_arn = aws_service_discovery_service.grafana.arn
  }
}
