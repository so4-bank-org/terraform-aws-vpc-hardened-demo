output "vpc_id" {
  description = "ID of the provisioned VPC."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR actually assigned to the VPC; verify it against the approved IPAM allocation after apply."
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "IDs of private subnets, ordered by availability zone."
  value       = module.vpc.private_subnets
}
