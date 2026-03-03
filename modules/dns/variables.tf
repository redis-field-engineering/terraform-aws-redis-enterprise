# =============================================================================
# DNS Module - Variables
# =============================================================================

variable "dns_zone_id" {
  description = "Route53 hosted zone ID."
  type        = string
}

variable "dns_domain" {
  description = "DNS domain (e.g., 'example.com.')."
  type        = string
}

variable "cluster_fqdn" {
  description = "Cluster FQDN."
  type        = string
}

variable "node_ips" {
  description = "List of node IP addresses."
  type        = list(string)
}

variable "region_suffix" {
  description = "Optional suffix for multi-region deployments (e.g., '-us-east-1')."
  type        = string
  default     = ""
}

