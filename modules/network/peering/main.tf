# =============================================================================
# VPC Peering Module - For Active-Active deployments
# =============================================================================

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# -----------------------------------------------------------------------------
# VPC Peering Connection
# -----------------------------------------------------------------------------

resource "aws_vpc_peering_connection" "peering" {
  vpc_id      = var.vpc1_id
  peer_vpc_id = var.vpc2_id
  peer_region = var.vpc2_region
  auto_accept = false

  tags = merge(var.tags, {
    Name = "${var.name}-peering"
    Side = "requester"
  })
}

# -----------------------------------------------------------------------------
# VPC Peering Connection Accepter (in peer region)
# -----------------------------------------------------------------------------

resource "aws_vpc_peering_connection_accepter" "peer" {
  provider                  = aws.peer
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
  auto_accept               = true

  tags = merge(var.tags, {
    Name = "${var.name}-peering"
    Side = "accepter"
  })
}

# -----------------------------------------------------------------------------
# Route Table Updates - Requester VPC
# -----------------------------------------------------------------------------

resource "aws_route" "requester_to_peer" {
  for_each = toset(var.vpc1_route_table_ids)

  route_table_id            = each.value
  destination_cidr_block    = var.vpc2_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}

# -----------------------------------------------------------------------------
# Route Table Updates - Accepter VPC
# -----------------------------------------------------------------------------

resource "aws_route" "peer_to_requester" {
  provider = aws.peer
  for_each = toset(var.vpc2_route_table_ids)

  route_table_id            = each.value
  destination_cidr_block    = var.vpc1_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}

