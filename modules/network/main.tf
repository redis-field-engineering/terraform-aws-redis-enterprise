# =============================================================================
# Network Module - VPC, Subnets, Security Groups
# =============================================================================

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # Use up to 3 AZs for subnet distribution
  available_azs = sort(data.aws_availability_zones.available.names)
  num_azs       = min(3, length(local.available_azs))
  selected_azs  = slice(local.available_azs, 0, local.num_azs)

  # Parse VPC CIDR to generate subnet CIDRs
  # e.g., 10.0.0.0/16 -> public subnets: 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24
  #                   -> private subnets: 10.0.11.0/24, 10.0.12.0/24, 10.0.13.0/24
  vpc_prefix = split(".", var.vpc_cidr)[0]
  vpc_second = split(".", var.vpc_cidr)[1]

  public_subnet_cidrs = {
    for idx, az in local.selected_azs :
    az => "${local.vpc_prefix}.${local.vpc_second}.${idx + 1}.0/24"
  }

  private_subnet_cidrs = {
    for idx, az in local.selected_azs :
    az => "${local.vpc_prefix}.${local.vpc_second}.${idx + 11}.0/24"
  }

  bastion_subnet_cidr = "${local.vpc_prefix}.${local.vpc_second}.100.0/24"
}

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.name}-vpc"
  })
}

# -----------------------------------------------------------------------------
# Internet Gateway
# -----------------------------------------------------------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}

# -----------------------------------------------------------------------------
# Public Subnets - One per availability zone
# -----------------------------------------------------------------------------

resource "aws_subnet" "public" {
  for_each = local.public_subnet_cidrs

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = !var.private_network

  tags = merge(var.tags, {
    Name = "${var.name}-public-${each.key}"
    Type = "public"
  })
}

# -----------------------------------------------------------------------------
# Private Subnets - One per availability zone (for private clusters)
# -----------------------------------------------------------------------------

resource "aws_subnet" "private" {
  for_each = var.private_network ? local.private_subnet_cidrs : {}

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = merge(var.tags, {
    Name = "${var.name}-private-${each.key}"
    Type = "private"
  })
}

# -----------------------------------------------------------------------------
# Bastion Subnet
# -----------------------------------------------------------------------------

resource "aws_subnet" "bastion" {
  count = var.create_bastion_subnet ? 1 : 0

  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.bastion_subnet_cidr
  availability_zone       = local.selected_azs[0]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name}-bastion"
    Type = "bastion"
  })
}

# -----------------------------------------------------------------------------
# Route Tables
# -----------------------------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${var.name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "bastion" {
  count = var.create_bastion_subnet ? 1 : 0

  subnet_id      = aws_subnet.bastion[0].id
  route_table_id = aws_route_table.public.id
}

# -----------------------------------------------------------------------------
# NAT Gateway (for private clusters)
# -----------------------------------------------------------------------------

resource "aws_eip" "nat" {
  count  = var.private_network ? 1 : 0
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name}-nat-eip"
  })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count = var.private_network ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = values(aws_subnet.public)[0].id

  tags = merge(var.tags, {
    Name = "${var.name}-nat"
  })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "private" {
  count  = var.private_network ? 1 : 0
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[0].id
  }

  tags = merge(var.tags, {
    Name = "${var.name}-private-rt"
  })
}

resource "aws_route_table_association" "private" {
  for_each = var.private_network ? aws_subnet.private : {}

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[0].id
}

# -----------------------------------------------------------------------------
# Security Groups
# -----------------------------------------------------------------------------

resource "aws_security_group" "redis" {
  name        = "${var.name}-redis-sg"
  description = "Security group for Redis Enterprise cluster"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.name}-redis-sg"
  })
}

# Allow all traffic within the security group (cluster internal communication)
resource "aws_security_group_rule" "internal" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.redis.id
  description       = "Allow all internal cluster traffic"
}

# SSH access
resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_source_cidrs
  security_group_id = aws_security_group.redis.id
  description       = "SSH access"
}

# Redis Enterprise Admin UI
resource "aws_security_group_rule" "admin_ui" {
  type              = "ingress"
  from_port         = 8443
  to_port           = 8443
  protocol          = "tcp"
  cidr_blocks       = var.allowed_source_cidrs
  security_group_id = aws_security_group.redis.id
  description       = "Redis Enterprise Admin UI"
}

# Redis Enterprise REST API
resource "aws_security_group_rule" "rest_api" {
  type              = "ingress"
  from_port         = 9443
  to_port           = 9443
  protocol          = "tcp"
  cidr_blocks       = var.allowed_source_cidrs
  security_group_id = aws_security_group.redis.id
  description       = "Redis Enterprise REST API"
}

# Discovery service
resource "aws_security_group_rule" "discovery" {
  type              = "ingress"
  from_port         = 8001
  to_port           = 8001
  protocol          = "tcp"
  cidr_blocks       = var.allowed_source_cidrs
  security_group_id = aws_security_group.redis.id
  description       = "Discovery service"
}

# Metrics
resource "aws_security_group_rule" "metrics" {
  type              = "ingress"
  from_port         = 8070
  to_port           = 8071
  protocol          = "tcp"
  cidr_blocks       = var.allowed_source_cidrs
  security_group_id = aws_security_group.redis.id
  description       = "Metrics endpoints"
}

# Database ports
resource "aws_security_group_rule" "database" {
  type              = "ingress"
  from_port         = 10000
  to_port           = 19999
  protocol          = "tcp"
  cidr_blocks       = var.allowed_source_cidrs
  security_group_id = aws_security_group.redis.id
  description       = "Database ports"
}

# Allow all outbound traffic
resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.redis.id
  description       = "Allow all outbound traffic"
}

