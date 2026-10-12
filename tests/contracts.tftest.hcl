mock_provider "aws" {
  override_during = plan
  mock_data "aws_partition" {
    defaults = { partition = "aws", dns_suffix = "amazonaws.com" }
  }
  mock_data "aws_region" {
    defaults = { name = "us-east-1" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "123456789012" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
}

variables {
  name                 = "demo-private-vpc"
  vpc_cidr             = "10.42.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  private_subnet_cidrs = ["10.42.1.0/24", "10.42.2.0/24"]
  environment          = "dev"
  owner                = "platform-team"
  cost_center          = "DEMO-001"
  data_classification  = "internal"
}

run "private_by_default" {
  command = plan
  assert {
    condition     = length(module.vpc.public_subnets) == 0 && length(module.vpc.nat_ids) == 0
    error_message = "The baseline must create no public subnets or NAT gateways."
  }
  assert {
    condition     = module.vpc.vpc_flow_log_destination_type == "cloud-watch-logs"
    error_message = "The baseline must send all VPC flow logs to CloudWatch Logs."
  }
}

run "allocate_explicit_cidr_from_ipam" {
  command = plan
  variables {
    ipv4_ipam_pool_id = "ipam-pool-0123456789abcdef0"
  }
  assert {
    condition     = output.vpc_cidr_block == var.vpc_cidr
    error_message = "IPAM-backed VPCs must retain the reviewed CIDR used by the private subnets."
  }
}

run "reject_invalid_ipam_pool_id" {
  command = plan
  variables {
    ipv4_ipam_pool_id = "not-an-ipam-pool"
  }
  expect_failures = [var.ipv4_ipam_pool_id]
}

run "reject_public_address_space" {
  command = plan
  variables {
    vpc_cidr             = "8.8.0.0/16"
    private_subnet_cidrs = ["8.8.1.0/24", "8.8.2.0/24"]
  }
  expect_failures = [var.vpc_cidr]
}

run "reject_duplicate_zones" {
  command = plan
  variables {
    availability_zones = ["us-east-1a", "us-east-1a"]
  }
  expect_failures = [var.availability_zones]
}

run "reject_overlapping_subnets" {
  command = plan
  variables {
    private_subnet_cidrs = ["10.42.1.0/24", "10.42.1.0/25"]
  }
  expect_failures = [var.private_subnet_cidrs]
}

run "reject_unsupported_log_retention" {
  command = plan
  variables {
    flow_logs_retention_days = 2
  }
  expect_failures = [var.flow_logs_retention_days]
}

run "allow_client_approved_shorter_retention" {
  command = plan
  variables {
    flow_logs_retention_days = 30
  }
}
