# =============================================================================
# Cluster Module - Variables
# =============================================================================

variable "name" {
  description = "Name prefix for resources."
  type        = string
}

variable "cluster_size" {
  description = "Number of nodes in the cluster."
  type        = number
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
}

variable "ami_id" {
  description = "AMI ID. If empty, latest Ubuntu 22.04 LTS will be used."
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Root volume size in GB."
  type        = number
  default     = 50
}

variable "root_volume_type" {
  description = "Root volume type."
  type        = string
  default     = "gp3"
}

variable "flash_enabled" {
  description = "Enable Redis on Flash."
  type        = bool
  default     = false
}

variable "rack_aware" {
  description = "Enable rack awareness."
  type        = bool
  default     = true
}

variable "private_cluster" {
  description = "Deploy without public IPs."
  type        = bool
  default     = false
}

# SSH
variable "ssh_user" {
  description = "SSH username."
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "SSH public key content."
  type        = string
}

# Network
variable "availability_zones" {
  description = "List of availability zones."
  type        = list(string)
}

variable "subnet_ids" {
  description = "Map of availability zone to subnet ID."
  type        = map(string)
}

variable "security_group_id" {
  description = "Security group ID for the instances."
  type        = string
}

# Redis Enterprise
variable "redis_download_url" {
  description = "URL to download Redis Enterprise."
  type        = string
}

variable "redis_admin_user" {
  description = "Redis Enterprise admin email."
  type        = string
}

variable "redis_admin_password" {
  description = "Redis Enterprise admin password."
  type        = string
  sensitive   = true
}

variable "cluster_fqdn" {
  description = "Cluster FQDN."
  type        = string
}

variable "wait_for_cluster" {
  description = "Wait for cluster initialization."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "placement_group_strategy" {
  description = <<-EOT
    Placement group strategy for cluster nodes. Options:
    - "none": No placement group (default)
    - "cluster": All nodes on same rack for lowest latency (~0.1ms)
    - "spread": Each node on different hardware for max fault tolerance
    - "partition": Nodes distributed across partitions

    Note: "cluster" strategy provides lowest network latency but reduces
    fault tolerance (all nodes affected by single rack failure).
  EOT
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "cluster", "spread", "partition"], var.placement_group_strategy)
    error_message = "placement_group_strategy must be one of: none, cluster, spread, partition"
  }
}

