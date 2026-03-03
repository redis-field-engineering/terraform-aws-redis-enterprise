# =============================================================================
# Bastion Module - Outputs
# =============================================================================

output "instance_id" {
  description = "Bastion instance ID."
  value       = aws_instance.bastion.id
}

output "public_ip" {
  description = "Bastion public IP address."
  value       = aws_eip.bastion.public_ip
}

output "private_ip" {
  description = "Bastion private IP address."
  value       = aws_instance.bastion.private_ip
}

output "ssh_command" {
  description = "SSH command to connect to bastion."
  value       = "ssh -i <key-file> ${var.ssh_user}@${aws_eip.bastion.public_ip}"
}

output "prometheus_url" {
  description = "Prometheus URL."
  value       = var.tools.prometheus ? "http://${aws_eip.bastion.public_ip}:9090" : null
}

output "grafana_url" {
  description = "Grafana URL."
  value       = var.tools.grafana ? "http://${aws_eip.bastion.public_ip}:3000" : null
}

output "redisinsight_url" {
  description = "RedisInsight URL."
  value       = var.tools.redisinsight ? "http://${aws_eip.bastion.public_ip}:5540" : null
}

output "security_group_id" {
  description = "Bastion security group ID."
  value       = aws_security_group.bastion.id
}

