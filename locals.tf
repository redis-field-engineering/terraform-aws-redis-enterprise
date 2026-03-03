# =============================================================================
# Local Values - Computed Configuration
# =============================================================================

locals {
  # ---------------------------------------------------------------------------
  # Resource Tags
  # ---------------------------------------------------------------------------
  common_tags = merge(
    var.tags,
    var.owner != "" ? { Owner = var.owner } : {},
    {
      ManagedBy = "terraform"
      Module    = "redis-enterprise-aws"
    }
  )

  # ---------------------------------------------------------------------------
  # Region Configuration
  # ---------------------------------------------------------------------------
  is_active_active = length(var.regions) > 1
  primary_region   = var.regions[0]

  # ---------------------------------------------------------------------------
  # Cluster FQDN
  # ---------------------------------------------------------------------------
  # Auto-generate cluster FQDN or use override
  cluster_fqdn = var.cluster_fqdn_override != "" ? var.cluster_fqdn_override : (
    var.create_dns && var.dns_domain != "" ?
    "cluster.${var.name}.${var.dns_domain}" :
    "cluster.${var.name}.local"
  )

  # Per-region cluster FQDNs for Active-Active
  region_cluster_fqdns = {
    for idx, region in var.regions :
    region => var.cluster_fqdn_override != "" ? var.cluster_fqdn_override : (
      var.create_dns && var.dns_domain != "" ?
      "cluster-${idx + 1}.${var.name}.${var.dns_domain}" :
      "cluster-${idx + 1}.${var.name}.local"
    )
  }

  # ---------------------------------------------------------------------------
  # SSH Key Handling
  # ---------------------------------------------------------------------------
  # If no SSH key provided, we'll generate one
  generate_ssh_key = var.ssh_public_key == ""

  # Use provided key or generated key
  ssh_public_key  = local.generate_ssh_key ? tls_private_key.generated[0].public_key_openssh : var.ssh_public_key
  ssh_private_key = local.generate_ssh_key ? tls_private_key.generated[0].private_key_openssh : var.ssh_private_key

  # ---------------------------------------------------------------------------
  # Network Configuration
  # ---------------------------------------------------------------------------
  # VPC CIDR generation for new networks
  # Base: 10.{region_index}.0.0/16
  region_vpc_cidrs = {
    for idx, region in var.regions :
    region => "10.${idx}.0.0/16"
  }

  # ---------------------------------------------------------------------------
  # Tool URLs for Bastion
  # ---------------------------------------------------------------------------
  memtier_url    = "https://github.com/RedisLabs/memtier_benchmark/archive/refs/tags/${var.memtier_version}.tar.gz"
  prometheus_url = "https://github.com/prometheus/prometheus/releases/download/v${var.prometheus_version}/prometheus-${var.prometheus_version}.linux-amd64.tar.gz"

  # ---------------------------------------------------------------------------
  # Password Generation
  # ---------------------------------------------------------------------------
  generate_password    = var.redis_admin_password == ""
  redis_admin_password = local.generate_password ? random_password.redis_admin[0].result : var.redis_admin_password

  # ---------------------------------------------------------------------------
  # Redis Download URL
  # ---------------------------------------------------------------------------
  # Construct download URL from version if not provided
  # Format: https://s3.amazonaws.com/redis-enterprise-software-downloads/{version}/redislabs-{version}-jammy-amd64.tar
  redis_download_url = var.redis_download_url != "" ? var.redis_download_url : "https://s3.amazonaws.com/redis-enterprise-software-downloads/${var.redis_version}/redislabs-${var.redis_version}-jammy-amd64.tar"
}

