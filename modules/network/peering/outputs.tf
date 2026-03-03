# =============================================================================
# VPC Peering Module - Outputs
# =============================================================================

output "peering_connection_id" {
  description = "VPC peering connection ID."
  value       = aws_vpc_peering_connection.peering.id
}

output "peering_connection_status" {
  description = "VPC peering connection status."
  value       = aws_vpc_peering_connection.peering.accept_status
}

