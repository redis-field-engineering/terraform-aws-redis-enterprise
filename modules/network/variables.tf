# =============================================================================
# Network Module - Variables
# =============================================================================

variable "name" {
  description = "Name prefix for resources."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "private_network" {
  description = "Whether to create private subnets and NAT gateway."
  type        = bool
  default     = false
}

variable "allowed_source_cidrs" {
  description = "CIDR ranges allowed to access the cluster."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "create_bastion_subnet" {
  description = "Whether to create a bastion subnet."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

