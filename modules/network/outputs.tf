# =============================================================================
# Network Module - Outputs
# =============================================================================

output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block."
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "Map of availability zone to public subnet ID."
  value = {
    for az, subnet in aws_subnet.public :
    az => subnet.id
  }
}

output "private_subnet_ids" {
  description = "Map of availability zone to private subnet ID."
  value = {
    for az, subnet in aws_subnet.private :
    az => subnet.id
  }
}

output "subnet_ids" {
  description = "Map of availability zone to subnet ID (private if available, otherwise public)."
  value = var.private_network ? {
    for az, subnet in aws_subnet.private :
    az => subnet.id
  } : {
    for az, subnet in aws_subnet.public :
    az => subnet.id
  }
}

output "bastion_subnet_id" {
  description = "Bastion subnet ID."
  value       = var.create_bastion_subnet ? aws_subnet.bastion[0].id : null
}

output "availability_zones" {
  description = "List of availability zones used."
  value       = local.selected_azs
}

output "security_group_id" {
  description = "Redis Enterprise security group ID."
  value       = aws_security_group.redis.id
}

