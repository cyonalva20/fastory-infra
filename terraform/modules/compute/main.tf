# ──────────────────────────────────────────────
# Módulo Compute — Fastory
# ──────────────────────────────────────────────
# Recursos de cómputo del proyecto.
# Incluye: Application Load Balancer (público), Target Group,
# Listener HTTP, IAM Role para EC2 (SSM + X-Ray), Launch Template
# con Docker y X-Ray daemon, y Auto Scaling Group.
# ──────────────────────────────────────────────

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ════════════════════════════════════════════════
# 1. APPLICATION LOAD BALANCER (público)
# ════════════════════════════════════════════════
# El ALB recibe tráfico HTTP desde Internet y lo
# distribuye a las instancias EC2 en subredes privadas.

resource "aws_lb" "main" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids
  drop_invalid_header_fields = true

  tags = {
    Name = "${local.name_prefix}-alb"
  }
}

# ════════════════════════════════════════════════
# 2. TARGET GROUP (HTTP 80)
# ════════════════════════════════════════════════
# Grupo de destino para las instancias EC2.
# Health check en /actuator/health (Spring Boot Actuator).

resource "aws_lb_target_group" "main" {
  name     = "${local.name_prefix}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    path                = "/actuator/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "${local.name_prefix}-tg"
  }
}

# ════════════════════════════════════════════════
# 3. LISTENER HTTP (puerto 80 -> Target Group)
# ════════════════════════════════════════════════
# Escucha en el puerto 80 y reenvía al Target Group.

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = {
    Name = "${local.name_prefix}-listener-http"
  }
}

# ════════════════════════════════════════════════
# 4. IAM ROLE PARA EC2
# ════════════════════════════════════════════════
# Permite a las instancias EC2 usar SSM (Session Manager)
# y enviar trazas a AWS X-Ray para observabilidad.

resource "aws_iam_role" "ec2" {
  name = "${local.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-ec2-role"
  }
}

# ── Política SSM: Permite administración remota via Session Manager ──

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ── Política X-Ray: Permite al daemon enviar trazas de rendimiento ──

resource "aws_iam_role_policy_attachment" "ec2_xray" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# ── Instance Profile: Asocia el IAM Role a las instancias EC2 ──

resource "aws_iam_instance_profile" "ec2" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2.name

  tags = {
    Name = "${local.name_prefix}-ec2-profile"
  }
}

# ════════════════════════════════════════════════
# 5. LAUNCH TEMPLATE
# ════════════════════════════════════════════════
# Plantilla de lanzamiento para las instancias EC2.
# Usa Amazon Linux 2023, t2.micro, instala Docker
# y el daemon de AWS X-Ray en el arranque.

# ── AMI más reciente de Amazon Linux 2023 (x86_64) ──

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "main" {
  name          = "${local.name_prefix}-lt"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Perfil IAM con permisos de SSM y X-Ray
  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2.arn
  }

  # Security Group para las instancias EC2
  vpc_security_group_ids = [var.ec2_security_group_id]

  # Script de inicialización: instala Docker y X-Ray daemon
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -euxo pipefail

    # ── Actualizar paquetes del sistema ──
    dnf update -y

    # ── Instalar y arrancar Docker ──
    dnf install -y docker
    systemctl enable docker
    systemctl start docker

    # ── Instalar y arrancar el daemon de AWS X-Ray ──
    # Descarga el RPM oficial de X-Ray para Amazon Linux
    curl -o /tmp/xray.rpm https://s3.us-east-2.amazonaws.com/aws-xray-assets.us-east-2/xray-daemon/aws-xray-daemon-3.x.rpm
    dnf install -y /tmp/xray.rpm
    systemctl enable xray
    systemctl start xray
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${local.name_prefix}-ec2"
    }
  }

  tags = {
    Name = "${local.name_prefix}-lt"
  }
}

# ════════════════════════════════════════════════
# 6. AUTO SCALING GROUP
# ════════════════════════════════════════════════
# Escala automáticamente las instancias EC2 entre
# min=1 y max=2 en las subredes privadas.
# Se asocia al Target Group del ALB.

resource "aws_autoscaling_group" "main" {
  name                = "${local.name_prefix}-asg"
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.main.arn]

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-ec2"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}
