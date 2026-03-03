# Terraform AWS Redis Enterprise Module

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.3-623CE4?logo=terraform)](https://www.terraform.io)
[![AWS Provider](https://img.shields.io/badge/AWS-%3E%3D5.0-FF9900?logo=amazonaws)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![Redis Enterprise](https://img.shields.io/badge/Redis%20Enterprise-8.0.6-DC382D?logo=redis)](https://redis.io/enterprise/)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

Terraform module to deploy Redis Enterprise Software clusters on Amazon Web Services. Supports single-region deployments, multi-region Active-Active configurations, Redis on Flash, and rack-awareness.

## Features

- **Single-region clusters** - Deploy highly available Redis Enterprise clusters
- **Active-Active** - Multi-region geo-distributed deployments with automatic failover
- **Rack awareness** - Distribute nodes across availability zones for fault tolerance
- **Redis on Flash** - Extend memory with NVMe storage for large datasets
- **Bastion host** - Optional jump host with pre-installed Redis tools
- **DNS integration** - Optional Route53 DNS records for cluster discovery
- **Auto-generated credentials** - Secure password and SSH key generation

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AWS Region                                      │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                              VPC                                       │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                    │  │
│  │  │   AZ-1      │  │   AZ-2      │  │   AZ-3      │                    │  │
│  │  │ ┌─────────┐ │  │ ┌─────────┐ │  │ ┌─────────┐ │                    │  │
│  │  │ │  Node 1 │ │  │ │  Node 2 │ │  │ │  Node 3 │ │  Redis Enterprise  │  │
│  │  │ │ (Master)│ │  │ │(Worker) │ │  │ │(Worker) │ │  Cluster           │  │
│  │  │ └─────────┘ │  │ └─────────┘ │  │ └─────────┘ │                    │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘                    │  │
│  │                                                                        │  │
│  │  ┌─────────────┐                                                       │  │
│  │  │  Bastion    │  Prometheus, Grafana, RedisInsight, memtier          │  │
│  │  └─────────────┘                                                       │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Quick Start

### Minimal Configuration

```hcl
module "redis_enterprise" {
  source = "github.com/redis-field-engineering/terraform-aws-redis-enterprise"

  name             = "my-redis"
  regions          = ["us-east-1"]
  redis_admin_user = "admin@example.com"
}
```

That's it! The module will:
- Create a VPC with appropriate subnets
- Deploy a 3-node Redis Enterprise cluster
- Generate secure admin password and SSH keys
- Create a bastion host with Redis tools

### Active-Active Deployment

```hcl
module "redis_active_active" {
  source = "github.com/redis-field-engineering/terraform-aws-redis-enterprise"

  name             = "redis-aa"
  regions          = ["us-east-1", "eu-west-1"]
  redis_admin_user = "admin@example.com"
}
```

### Production Configuration

```hcl
module "redis_production" {
  source = "github.com/redis-field-engineering/terraform-aws-redis-enterprise"

  name             = "redis-prod"
  regions          = ["us-east-1"]
  redis_admin_user = "admin@company.com"

  # Cluster sizing
  cluster_size  = 6
  instance_type = "r6i.2xlarge"
  rack_aware    = true

  # Redis on Flash
  flash_enabled = true

  # Security
  private_cluster      = true
  allowed_source_cidrs = ["10.0.0.0/8"]

  # Version (optional - defaults to latest)
  redis_version = "8.0.6-54"

  owner = "platform_team"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3 |
| aws | >= 5.0 |
| tls | >= 4.0 |
| random | >= 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name prefix for all resources | string | - | yes |
| regions | List of AWS regions | list(string) | - | yes |
| redis_admin_user | Admin email address | string | - | yes |
| redis_admin_password | Admin password (auto-generated if empty) | string | "" | no |
| redis_version | Redis Enterprise version | string | "8.0.6-54" | no |
| cluster_size | Number of nodes per cluster | number | 3 | no |
| instance_type | EC2 instance type | string | "m6i.xlarge" | no |
| rack_aware | Enable rack awareness | bool | true | no |
| flash_enabled | Enable Redis on Flash | bool | false | no |
| private_cluster | Deploy without public IPs | bool | false | no |
| create_bastion | Create bastion host | bool | true | no |
| create_dns | Create Route53 records | bool | false | no |

## Outputs

| Name | Description |
|------|-------------|
| admin_ui_urls | Redis Enterprise admin UI URLs per region |
| admin_credentials | Admin username and password (sensitive) |
| cluster_node_ips | Node IP addresses per region |
| bastion_ip | Bastion host public IP |
| bastion_ssh_command | SSH command to connect to bastion |
| generated_ssh_private_key | Generated SSH private key (sensitive) |

## Examples

- [Simple](./examples/simple) - Basic 3-node cluster
- [Active-Active](./examples/active-active) - Multi-region deployment
- [Rack-Aware](./examples/rack-aware) - Production cluster with HA
- [Existing Network](./examples/existing-network) - Deploy into existing VPC

## License

Apache 2.0 - See [LICENSE](LICENSE) for details.

