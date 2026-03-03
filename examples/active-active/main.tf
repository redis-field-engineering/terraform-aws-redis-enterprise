# =============================================================================
# Active-Active Redis Enterprise Cluster Example
# =============================================================================
# This example creates Redis Enterprise clusters in multiple regions
# for Active-Active geo-distributed deployment.
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
  region = var.regions[0]
}

module "redis_enterprise" {
  source = "../.."

  name = "redis-aa"

  # Multiple regions for Active-Active
  regions = var.regions

  # Redis Enterprise (password auto-generated, version defaults to 8.0.6-54)
  redis_admin_user = var.redis_admin_user

  # Cluster config
  cluster_size = 3
  rack_aware   = true

  # Bastion only in primary region
  create_bastion = true

  # Owner tag
  owner = var.owner
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "regions" {
  description = "AWS regions for Active-Active deployment"
  type        = list(string)
  default     = ["us-east-1", "eu-west-1"]
}

variable "redis_admin_user" {
  description = "Redis Enterprise admin email"
  type        = string
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
  description = "Redis Enterprise admin UI URLs per region"
  value       = module.redis_enterprise.admin_ui_urls
}

output "cluster_fqdns" {
  description = "Cluster FQDNs per region"
  value       = module.redis_enterprise.cluster_fqdns
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

