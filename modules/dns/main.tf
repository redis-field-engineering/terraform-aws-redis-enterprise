# =============================================================================
# DNS Module - Route53 Records
# =============================================================================

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

locals {
  # Parse cluster FQDN to get subdomain parts
  # e.g., cluster.redis.example.com -> cluster.redis
  cluster_subdomain = trimsuffix(var.cluster_fqdn, ".${trimsuffix(var.dns_domain, ".")}")
}

# -----------------------------------------------------------------------------
# A Records for each node
# -----------------------------------------------------------------------------

resource "aws_route53_record" "nodes" {
  count = length(var.node_ips)

  zone_id = var.dns_zone_id
  name    = "node${count.index + 1}${var.region_suffix}.${local.cluster_subdomain}"
  type    = "A"
  ttl     = 60
  records = [var.node_ips[count.index]]
}

# -----------------------------------------------------------------------------
# NS Record pointing to node A records
# -----------------------------------------------------------------------------

resource "aws_route53_record" "cluster_ns" {
  zone_id = var.dns_zone_id
  name    = "${local.cluster_subdomain}${var.region_suffix}"
  type    = "NS"
  ttl     = 60
  records = [for r in aws_route53_record.nodes : "${r.fqdn}."]
}

