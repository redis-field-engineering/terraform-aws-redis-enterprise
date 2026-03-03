# =============================================================================
# Simple Redis Enterprise Cluster Example
# =============================================================================
# This example creates a basic 3-node Redis Enterprise cluster in a single
# region with all default settings.
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

  name    = "redis-simple"
  regions = [var.region]

  # Redis Enterprise (password auto-generated, version defaults to 8.0.6-54)
  redis_admin_user = var.redis_admin_user

  # Default settings:
  # - cluster_size = 3
  # - rack_aware = true
  # - create_network = true
  # - create_bastion = true
  # - wait_for_cluster = true
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

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "admin_ui_urls" {
  description = "Redis Enterprise admin UI URLs"
  value       = module.redis_enterprise.admin_ui_urls
}

output "admin_credentials" {
  description = "Redis Enterprise admin credentials"
  value       = module.redis_enterprise.admin_credentials
  sensitive   = true
}

output "bastion_ssh_command" {
  description = "SSH command to connect to bastion"
  value       = module.redis_enterprise.bastion_ssh_command
}

output "ssh_private_key" {
  description = "Generated SSH private key"
  value       = module.redis_enterprise.generated_ssh_private_key
  sensitive   = true
}

