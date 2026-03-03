# =============================================================================
# VPC Peering Module - Variables
# =============================================================================

variable "name" {
  description = "Name prefix for resources."
  type        = string
}

variable "vpc1_id" {
  description = "ID of the first VPC (requester)."
  type        = string
}

variable "vpc1_cidr" {
  description = "CIDR block of the first VPC."
  type        = string
}

variable "vpc1_route_table_ids" {
  description = "List of route table IDs in the first VPC to update."
  type        = list(string)
}

variable "vpc2_id" {
  description = "ID of the second VPC (accepter)."
  type        = string
}

variable "vpc2_cidr" {
  description = "CIDR block of the second VPC."
  type        = string
}

variable "vpc2_region" {
  description = "Region of the second VPC."
  type        = string
}

variable "vpc2_route_table_ids" {
  description = "List of route table IDs in the second VPC to update."
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

