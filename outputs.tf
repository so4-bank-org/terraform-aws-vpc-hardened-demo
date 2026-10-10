output "vpc_id" {
  description = "ID of the provisioned VPC."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of private subnets, ordered by availability zone."
  value       = module.vpc.private_subnets
}
