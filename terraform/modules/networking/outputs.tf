# ──────────────────────────────────────────────
# Outputs — Módulo Networking
# ──────────────────────────────────────────────
# Estos valores se exponen al root module para que
# otros módulos (ECS, RDS, ALB, etc.) puedan referenciarlos.
# ──────────────────────────────────────────────

# ── VPC ──────────────────────────────────────

output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "Bloque CIDR de la VPC"
  value       = aws_vpc.main.cidr_block
}

# ── Subredes ─────────────────────────────────

output "public_subnet_ids" {
  description = "Lista de IDs de las subredes públicas"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Lista de IDs de las subredes privadas"
  value       = aws_subnet.private[*].id
}

output "public_subnet_cidrs" {
  description = "Lista de CIDRs de las subredes públicas"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "Lista de CIDRs de las subredes privadas"
  value       = aws_subnet.private[*].cidr_block
}

# ── Gateways ─────────────────────────────────

output "internet_gateway_id" {
  description = "ID del Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "ID del NAT Gateway administrado"
  value       = aws_nat_gateway.main.id
}

output "nat_gateway_public_ip" {
  description = "IP pública (Elastic IP) del NAT Gateway"
  value       = aws_eip.nat.public_ip
}

# ── Route Tables ─────────────────────────────

output "public_route_table_id" {
  description = "ID de la Route Table pública"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID de la Route Table privada"
  value       = aws_route_table.private.id
}
