# =============================================================================
# Rack-Aware Redis Enterprise Cluster Example
# =============================================================================
# This example creates a larger cluster with rack awareness enabled,
# suitable for production deployments requiring high availability.
# =============================================================================

terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "redis_enterprise" {
  source = "../.."

  name    = "redis-rack-aware"
  regions = [var.region]

  # Redis Enterprise (password auto-generated, version defaults to 8.0.6-54)
  redis_admin_user = var.redis_admin_user

  # Larger cluster with rack awareness
  cluster_size = 6
  rack_aware   = true

  # High-performance instance type for production
  instance_type = "m6i.2xlarge"

  # Redis on Flash for large datasets
  flash_enabled = var.flash_enabled

  # Private cluster (access through bastion only)
  private_cluster = false

  # Restrict access to corporate IP ranges
  allowed_source_cidrs = var.allowed_source_cidrs

  # Owner tag
  owner = var.owner

  tags = {
    Environment = "production"
    Tier        = "database"
  }
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "redis_admin_user" {
  description = "Redis Enterprise admin email"
  type        = string
}

variable "flash_enabled" {
  description = "Enable Redis on Flash"
  type        = bool
  default     = false
}

variable "allowed_source_cidrs" {
  description = "CIDR ranges allowed to access the cluster"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "owner" {
  description = "Owner tag"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "admin_ui_urls" {
  description = "Redis Enterprise admin UI URLs"
  value       = module.redis_enterprise.admin_ui_urls
}

output "cluster_node_ips" {
  description = "Cluster node IPs"
  value       = module.redis_enterprise.cluster_node_ips
}

output "admin_credentials" {
  description = "Redis Enterprise admin credentials"
  value       = module.redis_enterprise.admin_credentials
  sensitive   = true
}

