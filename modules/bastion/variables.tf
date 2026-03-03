# =============================================================================
# Bastion Module - Variables
# =============================================================================

variable "name" {
  description = "Name for the bastion host."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.medium"
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

variable "ssh_user" {
  description = "SSH username."
  type        = string
  default     = "ubuntu"
}

variable "key_name" {
  description = "Key pair name for SSH access."
  type        = string
}

# Network
variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the bastion host."
  type        = string
}

variable "cluster_security_group_id" {
  description = "Security group ID of the Redis cluster (for internal access)."
  type        = string
}

# Redis Cluster
variable "cluster_fqdn" {
  description = "Redis cluster FQDN."
  type        = string
}

# Tools
variable "tools" {
  description = "Tools to install on bastion."
  type = object({
    memtier      = optional(bool, true)
    redis_cli    = optional(bool, true)
    prometheus   = optional(bool, true)
    grafana      = optional(bool, true)
    redisinsight = optional(bool, true)
  })
  default = {}
}

variable "memtier_url" {
  description = "URL to download memtier_benchmark."
  type        = string
}

variable "prometheus_url" {
  description = "URL to download Prometheus."
  type        = string
}

variable "grafana_version" {
  description = "Grafana version to install."
  type        = string
  default     = "10.2.2"
}

variable "java_version" {
  description = "Java version to install."
  type        = string
  default     = "21"
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

