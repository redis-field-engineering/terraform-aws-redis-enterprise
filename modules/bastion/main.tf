# =============================================================================
# Bastion Module - Bastion Host with Tools
# =============================================================================

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

# Find latest Ubuntu 22.04 LTS AMI if not provided
data "aws_ami" "ubuntu" {
  count       = var.ami_id == "" ? 1 : 0
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  ami_id = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu[0].id
}

# -----------------------------------------------------------------------------
# Elastic IP for Bastion
# -----------------------------------------------------------------------------

resource "aws_eip" "bastion" {
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name}-eip"
  })
}

# -----------------------------------------------------------------------------
# Security Group for Bastion
# -----------------------------------------------------------------------------

resource "aws_security_group" "bastion" {
  name        = "${var.name}-sg"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # Prometheus
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Prometheus"
  }

  # Grafana
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Grafana"
  }

  # RedisInsight
  ingress {
    from_port   = 5540
    to_port     = 5540
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "RedisInsight"
  }

  # All outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.name}-sg"
  })
}

# -----------------------------------------------------------------------------
# Bastion Instance
# -----------------------------------------------------------------------------

resource "aws_instance" "bastion" {
  ami                    = local.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.bastion.id, var.cluster_security_group_id]

  associate_public_ip_address = true

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true

    tags = merge(var.tags, {
      Name = "${var.name}-root"
    })
  }

  user_data = templatefile("${path.module}/templates/prepare_client.sh.tpl", {
    ssh_user             = var.ssh_user
    cluster_fqdn         = var.cluster_fqdn
    memtier_url          = var.memtier_url
    prometheus_url       = var.prometheus_url
    grafana_version      = var.grafana_version
    java_version         = var.java_version
    install_memtier      = var.tools.memtier
    install_prometheus   = var.tools.prometheus
    install_grafana      = var.tools.grafana
    install_redisinsight = var.tools.redisinsight
    install_redis_cli    = var.tools.redis_cli
  })

  tags = merge(var.tags, {
    Name = var.name
  })

  lifecycle {
    ignore_changes = [user_data]
  }
}

# -----------------------------------------------------------------------------
# Associate EIP with Bastion
# -----------------------------------------------------------------------------

resource "aws_eip_association" "bastion" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion.id
}

