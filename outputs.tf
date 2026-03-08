# =============================================================================
# Redis Enterprise AWS Module - Outputs
# =============================================================================

# -----------------------------------------------------------------------------
# Cluster Information
# -----------------------------------------------------------------------------

output "cluster_fqdns" {
  description = "Cluster FQDNs for each region."
  value = {
    for region, cluster in module.cluster :
    region => cluster.cluster_fqdn
  }
}

output "cluster_node_ips" {
  description = "Node IP addresses for each region."
  value = {
    for region, cluster in module.cluster :
    region => {
      public  = cluster.node_public_ips
      private = cluster.node_private_ips
    }
  }
}

# -----------------------------------------------------------------------------
# Bastion Information
# -----------------------------------------------------------------------------

output "bastion_ip" {
  description = "Bastion host public IP address (if created)."
  value       = var.create_bastion ? module.bastion[0].public_ip : null
}

output "bastion_ssh_command" {
  description = "SSH command to connect to bastion host."
  value       = var.create_bastion ? module.bastion[0].ssh_command : null
}

output "prometheus_url" {
  description = "Prometheus URL on bastion (if installed)."
  value       = var.create_bastion ? module.bastion[0].prometheus_url : null
}

output "grafana_url" {
  description = "Grafana URL on bastion (if installed)."
  value       = var.create_bastion ? module.bastion[0].grafana_url : null
}

output "redisinsight_url" {
  description = "RedisInsight URL on bastion (if installed)."
  value       = var.create_bastion ? module.bastion[0].redisinsight_url : null
}

# -----------------------------------------------------------------------------
# Network Information
# -----------------------------------------------------------------------------

output "vpc_ids" {
  description = "VPC IDs for each region."
  value = var.create_network ? {
    for region, network in module.network :
    region => network.vpc_id
  } : {}
}

output "subnet_ids" {
  description = "Subnet IDs for each region."
  value = var.create_network ? {
    for region, network in module.network :
    region => network.subnet_ids
  } : {}
}

# -----------------------------------------------------------------------------
# DNS Information
# -----------------------------------------------------------------------------

output "dns_records" {
  description = "DNS records created (if DNS is enabled)."
  value = var.create_dns ? {
    for region, dns in module.dns :
    region => dns.node_dns_names
  } : {}
}

# -----------------------------------------------------------------------------
# SSH Key (if generated)
# -----------------------------------------------------------------------------

output "generated_ssh_private_key" {
  description = "Generated SSH private key (only if no key was provided). Save this securely!"
  value       = local.generate_ssh_key ? tls_private_key.generated[0].private_key_openssh : null
  sensitive   = true
}

output "generated_ssh_public_key" {
  description = "Generated SSH public key (only if no key was provided)."
  value       = local.generate_ssh_key ? tls_private_key.generated[0].public_key_openssh : null
}

# -----------------------------------------------------------------------------
# Connection Information
# -----------------------------------------------------------------------------

output "admin_ui_urls" {
  description = "Redis Enterprise admin UI URLs for each region."
  value = {
    for region, cluster in module.cluster :
    region => cluster.admin_ui_url
  }
}

output "admin_credentials" {
  description = "Redis Enterprise admin credentials."
  value = {
    username = var.redis_admin_user
    password = local.redis_admin_password
  }
  sensitive = true
}

output "redis_download_url" {
  description = "The Redis Enterprise download URL being used."
  value       = local.redis_download_url
}

# -----------------------------------------------------------------------------
# Placement Group Information
# -----------------------------------------------------------------------------

output "placement_group_names" {
  description = "Placement group names for each region (null if placement_group_strategy is 'none')."
  value = {
    for region, cluster in module.cluster :
    region => cluster.placement_group_name
  }
}

output "placement_group_ids" {
  description = "Placement group IDs for each region (null if placement_group_strategy is 'none')."
  value = {
    for region, cluster in module.cluster :
    region => cluster.placement_group_id
  }
}

