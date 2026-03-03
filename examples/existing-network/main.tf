# =============================================================================
# Existing Network Redis Enterprise Cluster Example
# =============================================================================
# This example deploys Redis Enterprise into an existing VPC and subnets.
# Use this when you already have network infrastructure in place.
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

  name    = "redis-existing-vpc"
  regions = [var.region]

  # Use existing network
  create_network    = false
  vpc_id            = var.vpc_id
  subnet_ids        = { (var.region) = var.subnet_ids }
  security_group_id = var.security_group_id

  # Redis Enterprise (password auto-generated, version defaults to 8.0.6-54)
  redis_admin_user = var.redis_admin_user

  # SSH keys - provide your own when using existing network
  ssh_public_key  = var.ssh_public_key
  ssh_private_key = var.ssh_private_key

  # Don't create bastion if using existing network
  create_bastion = false

  # Owner tag
  owner = var.owner
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "Existing VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Map of AZ to subnet ID"
  type        = map(string)
}

variable "security_group_id" {
  description = "Existing security group ID"
  type        = string
}

variable "redis_admin_user" {
  description = "Redis Enterprise admin email"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key content"
  type        = string
}

variable "ssh_private_key" {
  description = "SSH private key content"
  type        = string
  sensitive   = true
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

