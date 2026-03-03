# =============================================================================
# DNS Module - Outputs
# =============================================================================

output "node_dns_names" {
  description = "DNS names for each node."
  value       = aws_route53_record.nodes[*].fqdn
}

output "cluster_ns_record" {
  description = "Cluster NS record name."
  value       = aws_route53_record.cluster_ns.fqdn
}

