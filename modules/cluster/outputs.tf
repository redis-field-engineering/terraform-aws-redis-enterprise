# =============================================================================
# Cluster Module - Outputs
# =============================================================================

output "master_instance_id" {
  description = "Master node instance ID."
  value       = aws_instance.master.id
}

output "worker_instance_ids" {
  description = "Worker node instance IDs."
  value       = aws_instance.workers[*].id
}

output "node_private_ips" {
  description = "Private IP addresses of all nodes."
  value       = concat([aws_instance.master.private_ip], aws_instance.workers[*].private_ip)
}

output "node_public_ips" {
  description = "Public IP addresses of all nodes (empty if private cluster)."
  value       = var.private_cluster ? [] : concat(
    [aws_instance.master.public_ip],
    aws_instance.workers[*].public_ip
  )
}

output "primary_az" {
  description = "Primary availability zone (master node location)."
  value       = local.node_azs[0]
}

output "cluster_fqdn" {
  description = "Cluster FQDN."
  value       = var.cluster_fqdn
}

output "admin_ui_url" {
  description = "Redis Enterprise admin UI URL."
  value       = var.private_cluster ? "https://${aws_instance.master.private_ip}:8443" : "https://${aws_instance.master.public_ip}:8443"
}

output "key_pair_name" {
  description = "Key pair name for SSH access."
  value       = aws_key_pair.redis.key_name
}

