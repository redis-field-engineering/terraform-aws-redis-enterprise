# =============================================================================
# Redis Enterprise AWS Module - Main Configuration
# =============================================================================
# This module deploys Redis Enterprise clusters on AWS with support for:
# - Single region deployments
# - Multi-region Active-Active deployments
# - Rack-aware configurations
# - Optional bastion host with monitoring tools
# - Optional DNS configuration
# =============================================================================

# -----------------------------------------------------------------------------
# SSH Key Generation (if not provided)
# -----------------------------------------------------------------------------

resource "tls_private_key" "generated" {
  count     = local.generate_ssh_key ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# -----------------------------------------------------------------------------
# Random Password Generation (if not provided)
# -----------------------------------------------------------------------------

resource "random_password" "redis_admin" {
  count   = local.generate_password ? 1 : 0
  length  = 24
  special = false
}

# -----------------------------------------------------------------------------
# Network Module - One per region
# -----------------------------------------------------------------------------

module "network" {
  source   = "./modules/network"
  for_each = var.create_network ? toset(var.regions) : toset([])

  name                  = "${var.name}-${each.key}"
  vpc_cidr              = local.region_vpc_cidrs[each.key]
  private_network       = var.private_cluster
  allowed_source_cidrs  = var.allowed_source_cidrs
  create_bastion_subnet = var.create_bastion && each.key == local.primary_region
  tags                  = local.common_tags
}

# -----------------------------------------------------------------------------
# Cluster Module - One per region
# -----------------------------------------------------------------------------

module "cluster" {
  source   = "./modules/cluster"
  for_each = toset(var.regions)

  name                     = "${var.name}-${each.key}"
  cluster_size             = var.cluster_size
  rack_aware               = var.rack_aware
  placement_group_strategy = var.placement_group_strategy

  # Instance configuration
  instance_type    = var.instance_type
  ami_id           = var.ami_id
  root_volume_size = var.root_volume_size
  root_volume_type = var.root_volume_type
  flash_enabled    = var.flash_enabled
  private_cluster  = var.private_cluster

  # SSH
  ssh_user       = var.ssh_user
  ssh_public_key = local.ssh_public_key

  # Network configuration
  availability_zones = var.create_network ? module.network[each.key].availability_zones : keys(var.subnet_ids[each.key])
  subnet_ids         = var.create_network ? module.network[each.key].subnet_ids : var.subnet_ids[each.key]
  security_group_id  = var.create_network ? module.network[each.key].security_group_id : var.security_group_id

  # Redis Enterprise
  redis_download_url   = local.redis_download_url
  redis_admin_user     = var.redis_admin_user
  redis_admin_password = local.redis_admin_password
  cluster_fqdn         = local.is_active_active ? local.region_cluster_fqdns[each.key] : local.cluster_fqdn
  wait_for_cluster     = var.wait_for_cluster

  tags = local.common_tags

  depends_on = [module.network]
}

# -----------------------------------------------------------------------------
# Bastion Module - Only in primary region
# -----------------------------------------------------------------------------

module "bastion" {
  source = "./modules/bastion"
  count  = var.create_bastion ? 1 : 0

  name          = "${var.name}-bastion"
  instance_type = var.bastion_instance_type
  ami_id        = var.ami_id
  ssh_user      = var.ssh_user
  key_name      = module.cluster[local.primary_region].key_pair_name
  cluster_fqdn  = local.cluster_fqdn

  # Network
  vpc_id                    = var.create_network ? module.network[local.primary_region].vpc_id : var.vpc_id
  subnet_id                 = var.create_network ? module.network[local.primary_region].bastion_subnet_id : var.bastion_subnet_id
  cluster_security_group_id = var.create_network ? module.network[local.primary_region].security_group_id : var.security_group_id

  # Tools configuration
  tools           = var.bastion_tools
  memtier_url     = local.memtier_url
  prometheus_url  = local.prometheus_url
  grafana_version = var.grafana_version
  java_version    = var.java_version

  tags = local.common_tags

  depends_on = [module.cluster]
}

# -----------------------------------------------------------------------------
# DNS Module - One per region (if enabled)
# -----------------------------------------------------------------------------

module "dns" {
  source   = "./modules/dns"
  for_each = var.create_dns ? toset(var.regions) : toset([])

  dns_zone_id   = var.dns_zone_id
  dns_domain    = var.dns_domain
  cluster_fqdn  = local.is_active_active ? local.region_cluster_fqdns[each.key] : local.cluster_fqdn
  node_ips      = module.cluster[each.key].node_private_ips
  region_suffix = local.is_active_active ? "-${each.key}" : ""

  depends_on = [module.cluster]
}

