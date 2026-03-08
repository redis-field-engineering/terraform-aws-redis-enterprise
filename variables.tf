# =============================================================================
# Redis Enterprise AWS Module - Input Variables
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name prefix for all resources. Used in resource naming."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.name))
    error_message = "Name must start with a letter, contain only lowercase letters, numbers, and hyphens, and be max 63 characters."
  }
}

variable "regions" {
  description = "List of AWS regions for the cluster. Single region for standard deployment, multiple for Active-Active."
  type        = list(string)

  validation {
    condition     = length(var.regions) >= 1 && length(var.regions) <= 5
    error_message = "Must specify between 1 and 5 regions."
  }
}

variable "redis_admin_user" {
  description = "Email address for the Redis Enterprise admin user."
  type        = string
}

variable "redis_admin_password" {
  description = "Password for the Redis Enterprise admin user. If not provided, a secure random password will be generated."
  type        = string
  default     = ""
  sensitive   = true
}

variable "redis_version" {
  description = "Redis Enterprise version to install (e.g., '8.0.10-76'). Format: {version}-{build}. Used to construct download URL if redis_download_url is not provided."
  type        = string
  default     = "8.0.10-76"
}

variable "redis_download_url" {
  description = "Full URL to download Redis Enterprise tarball. If not provided, URL is constructed from redis_version."
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# SSH Configuration
# -----------------------------------------------------------------------------

variable "ssh_public_key" {
  description = "SSH public key content (not path) for instance access. If not provided, a key will be generated."
  type        = string
  default     = ""
}

variable "ssh_private_key" {
  description = "SSH private key content (not path) for provisioner access. Required if ssh_public_key is provided."
  type        = string
  default     = ""
  sensitive   = true
}

variable "ssh_user" {
  description = "SSH username for instance access."
  type        = string
  default     = "ubuntu"
}

# -----------------------------------------------------------------------------
# Cluster Configuration
# -----------------------------------------------------------------------------

variable "cluster_size" {
  description = "Number of nodes per cluster (per region for Active-Active)."
  type        = number
  default     = 3

  validation {
    condition     = var.cluster_size >= 3
    error_message = "Cluster size must be at least 3 for production deployments."
  }
}

variable "rack_aware" {
  description = "Enable rack awareness (nodes distributed across availability zones)."
  type        = bool
  default     = true
}

variable "placement_group_strategy" {
  description = <<-EOT
    Placement group strategy for cluster nodes. Options:
    - "none": No placement group (default)
    - "cluster": All nodes on same rack for lowest latency (~0.1ms vs ~0.5ms)
    - "spread": Each node on different hardware for max fault tolerance
    - "partition": Nodes distributed across partitions

    Note: "cluster" strategy provides lowest network latency but reduces
    fault tolerance (all nodes affected by single rack failure).
    Typically used with rack_aware = false for latency-sensitive PoCs.
  EOT
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "cluster", "spread", "partition"], var.placement_group_strategy)
    error_message = "placement_group_strategy must be one of: none, cluster, spread, partition"
  }
}

variable "flash_enabled" {
  description = "Enable Redis on Flash (requires instances with NVMe instance store)."
  type        = bool
  default     = false
}

variable "instance_type" {
  description = "AWS EC2 instance type for Redis Enterprise nodes."
  type        = string
  default     = "m6i.xlarge"
}

variable "ami_id" {
  description = "AMI ID for instances. If not provided, latest Ubuntu 22.04 LTS will be used."
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB."
  type        = number
  default     = 50
}

variable "root_volume_type" {
  description = "Root EBS volume type (gp3, gp2, io1, io2)."
  type        = string
  default     = "gp3"
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------

variable "create_network" {
  description = "Whether to create a new VPC network. Set to false to use existing network."
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "Existing VPC ID to use. Required if create_network is false."
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Map of region to list of subnet IDs. Required if create_network is false."
  type        = map(list(string))
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC (when creating new network)."
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_cluster" {
  description = "Deploy cluster without public IPs (requires bastion or VPN for access)."
  type        = bool
  default     = false
}

variable "allowed_source_cidrs" {
  description = "CIDR ranges allowed to access the cluster. Default allows all (use with caution)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "security_group_id" {
  description = "Existing security group ID for cluster instances. Required if create_network is false."
  type        = string
  default     = ""
}

variable "bastion_subnet_id" {
  description = "Subnet ID for bastion host. Required if create_network is false and create_bastion is true."
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Bastion Configuration
# -----------------------------------------------------------------------------

variable "create_bastion" {
  description = "Whether to create a bastion host with Redis tools."
  type        = bool
  default     = true
}

variable "bastion_instance_type" {
  description = "AWS EC2 instance type for bastion host."
  type        = string
  default     = "t3.medium"
}

variable "bastion_tools" {
  description = "Tools to install on bastion. Set individual tools to false to skip installation."
  type = object({
    memtier      = optional(bool, true)
    redis_cli    = optional(bool, true)
    prometheus   = optional(bool, true)
    grafana      = optional(bool, true)
    redisinsight = optional(bool, true)
  })
  default = {}
}

variable "memtier_version" {
  description = "Memtier benchmark version to install."
  type        = string
  default     = "2.1.1"
}

variable "prometheus_version" {
  description = "Prometheus version to install."
  type        = string
  default     = "2.48.0"
}

variable "grafana_version" {
  description = "Grafana version to install."
  type        = string
  default     = "10.2.2"
}

variable "java_version" {
  description = "Java version to install on bastion."
  type        = string
  default     = "21"
}

# -----------------------------------------------------------------------------
# DNS Configuration
# -----------------------------------------------------------------------------

variable "create_dns" {
  description = "Whether to create Route53 DNS records for the cluster."
  type        = bool
  default     = false
}

variable "dns_zone_id" {
  description = "Route53 hosted zone ID (must already exist)."
  type        = string
  default     = ""
}

variable "dns_domain" {
  description = "DNS domain for cluster records (e.g., 'example.com'). Must match the hosted zone."
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Resource Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "owner" {
  description = "Owner tag for resources."
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Advanced Options
# -----------------------------------------------------------------------------

variable "wait_for_cluster" {
  description = "Wait for Redis Enterprise cluster to be fully initialized before completing."
  type        = bool
  default     = true
}

variable "cluster_fqdn_override" {
  description = "Override the auto-generated cluster FQDN. Leave empty for auto-generation."
  type        = string
  default     = ""
}

