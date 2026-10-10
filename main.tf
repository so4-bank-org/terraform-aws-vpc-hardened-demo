locals {
  required_tags = {
    Environment        = var.environment
    Owner              = var.owner
    CostCenter         = var.cost_center
    DataClassification = var.data_classification
    ManagedBy          = "terraform"
  }
}

# This child module is the exact upstream v5.19.0 source snapshot, mirrored at
# commit 961c9b51e3ed3959d9419f019e7085c087bf7297. Keeping the pinned
# snapshot in this release makes consumer runs independent of Git credentials.
module "vpc" {
  source = "./modules/upstream"

  name            = var.name
  cidr            = var.vpc_cidr
  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidrs

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

  # Delivery bucket policy, encryption, retention and monitoring are supplied
  # and independently verified by the platform team.
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = false
  create_flow_log_cloudwatch_iam_role  = false
  flow_log_destination_type            = "s3"
  flow_log_destination_arn             = var.flow_logs_bucket_arn
  flow_log_traffic_type                = "ALL"

  tags = local.required_tags
}
