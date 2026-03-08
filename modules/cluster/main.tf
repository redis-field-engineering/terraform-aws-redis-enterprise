# =============================================================================
# Cluster Module - Redis Enterprise EC2 Instances
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

  # Distribute nodes across availability zones (only if rack_aware is true)
  # When rack_aware is false, all nodes go to the first AZ for minimal latency
  node_azs = [
    for i in range(var.cluster_size) :
    var.rack_aware ? var.availability_zones[i % length(var.availability_zones)] : var.availability_zones[0]
  ]

  # Map AZ to subnet ID
  az_to_subnet = {
    for az, subnet_id in var.subnet_ids :
    az => subnet_id
  }
}

# -----------------------------------------------------------------------------
# IAM Role and Instance Profile
# -----------------------------------------------------------------------------

resource "aws_iam_role" "redis" {
  name = "${var.name}-redis-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "redis" {
  name = "${var.name}-redis-policy"
  role = aws_iam_role.redis.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "redis" {
  name = "${var.name}-redis-profile"
  role = aws_iam_role.redis.name

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Placement Group (for low-latency deployments)
# -----------------------------------------------------------------------------

resource "aws_placement_group" "cluster" {
  count    = var.placement_group_strategy != "none" ? 1 : 0
  name     = "${var.name}-placement"
  strategy = var.placement_group_strategy

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Key Pair
# -----------------------------------------------------------------------------

resource "aws_key_pair" "redis" {
  key_name   = "${var.name}-key"
  public_key = var.ssh_public_key

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Master Node
# -----------------------------------------------------------------------------

resource "aws_instance" "master" {
  ami                    = local.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.redis.key_name
  subnet_id              = local.az_to_subnet[local.node_azs[0]]
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.redis.name
  placement_group        = var.placement_group_strategy != "none" ? aws_placement_group.cluster[0].id : null

  associate_public_ip_address = !var.private_cluster

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    encrypted   = true

    tags = merge(var.tags, {
      Name = "${var.name}-node-0-root"
    })
  }

  user_data = templatefile("${path.module}/templates/install.sh.tpl", {
    ssh_user             = var.ssh_user
    redis_download_url   = var.redis_download_url
    redis_admin_user     = var.redis_admin_user
    redis_admin_password = var.redis_admin_password
    cluster_fqdn         = var.cluster_fqdn
    flash_enabled        = var.flash_enabled
    node_index           = 0
    is_master            = true
    master_ip            = ""
    rack_id              = var.rack_aware ? local.node_azs[0] : ""
  })

  tags = merge(var.tags, {
    Name      = "${var.name}-node-0"
    NodeIndex = "0"
    Role      = "master"
  })

  lifecycle {
    ignore_changes = [user_data]
  }
}

# -----------------------------------------------------------------------------
# Worker Nodes
# -----------------------------------------------------------------------------

resource "aws_instance" "workers" {
  count = var.cluster_size - 1

  ami                    = local.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.redis.key_name
  subnet_id              = local.az_to_subnet[local.node_azs[count.index + 1]]
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.redis.name
  placement_group        = var.placement_group_strategy != "none" ? aws_placement_group.cluster[0].id : null

  associate_public_ip_address = !var.private_cluster

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    encrypted   = true

    tags = merge(var.tags, {
      Name = "${var.name}-node-${count.index + 1}-root"
    })
  }

  user_data = templatefile("${path.module}/templates/install.sh.tpl", {
    ssh_user             = var.ssh_user
    redis_download_url   = var.redis_download_url
    redis_admin_user     = var.redis_admin_user
    redis_admin_password = var.redis_admin_password
    cluster_fqdn         = var.cluster_fqdn
    flash_enabled        = var.flash_enabled
    node_index           = count.index + 1
    is_master            = false
    master_ip            = aws_instance.master.private_ip
    rack_id              = var.rack_aware ? local.node_azs[count.index + 1] : ""
  })

  tags = merge(var.tags, {
    Name      = "${var.name}-node-${count.index + 1}"
    NodeIndex = tostring(count.index + 1)
    Role      = "worker"
  })

  lifecycle {
    ignore_changes = [user_data]
  }

  depends_on = [aws_instance.master]
}

# -----------------------------------------------------------------------------
# Wait for cluster initialization
# -----------------------------------------------------------------------------

resource "null_resource" "wait_for_cluster" {
  count = var.wait_for_cluster ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for Redis Enterprise cluster to initialize..."
      for i in $(seq 1 60); do
        # Check if the REST API port is responding (returns 401 Unauthorized when cluster is ready)
        HTTP_CODE=$(curl -sk -o /dev/null -w "%%{http_code}" https://${aws_instance.master.public_ip}:9443/v1/cluster 2>/dev/null)
        if [ "$HTTP_CODE" = "401" ]; then
          echo "Cluster is ready! (API responding with auth required)"
          exit 0
        fi
        echo "Waiting... ($i/60) - HTTP code: $HTTP_CODE"
        sleep 30
      done
      echo "Warning: Timeout waiting for cluster, but continuing..."
      exit 0
    EOT
  }

  depends_on = [aws_instance.master, aws_instance.workers]
}

