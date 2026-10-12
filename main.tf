locals {
  required_tags = {
    Environment        = var.environment
    Owner              = var.owner
    CostCenter         = var.cost_center
    DataClassification = var.data_classification
    ManagedBy          = "terraform"
  }
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

# This child module is the exact upstream v5.19.0 source snapshot, mirrored at
# commit 961c9b51e3ed3959d9419f019e7085c087bf7297. Keeping the pinned
# snapshot in this release makes consumer runs independent of Git credentials.
module "vpc" {
  source = "./modules/upstream"

  name              = var.name
  cidr              = var.vpc_cidr
  ipv4_ipam_pool_id = var.ipv4_ipam_pool_id
  azs               = var.availability_zones
  private_subnets   = var.private_subnet_cidrs

  # Keep the explicit CIDR so the reviewed subnets remain deterministic. When
  # a pool ID is set, AWS allocates this exact CIDR from that pool. Upstream's
  # use_ipam_pool=true would discard the explicit CIDR and choose a range.

  # Private-only baseline: no internet gateway, public subnet, NAT or public IP.
  create_igw              = false
  enable_nat_gateway      = false
  map_public_ip_on_launch = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  # The default security group must not permit ingress or egress.
  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []

  # Keep flow logging enabled without requiring an S3 bucket. The created
  # CloudWatch log group has finite retention and is retained on destroy.
  enable_flow_log                                 = true
  create_flow_log_cloudwatch_log_group            = true
  create_flow_log_cloudwatch_iam_role             = true
  flow_log_destination_type                       = "cloud-watch-logs"
  flow_log_traffic_type                           = "ALL"
  flow_log_cloudwatch_log_group_retention_in_days = var.flow_logs_retention_days
  flow_log_cloudwatch_log_group_kms_key_id        = var.flow_logs_kms_key_arn
  flow_log_cloudwatch_log_group_skip_destroy      = true
  vpc_flow_log_permissions_boundary               = var.flow_logs_permissions_boundary_arn

  # Restrict the delivery role to flow logs created in this account and region.
  # The flow-log ID is not known until creation, so AWS documents a wildcard.
  flow_log_cloudwatch_iam_role_conditions = [
    {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    },
    {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:vpc-flow-log/*"]
    }
  ]

  tags = local.required_tags
}
