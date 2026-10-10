variable "name" {
  description = "VPC name."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{2,31}$", var.name))
    error_message = "Use 3-32 lowercase letters, numbers or hyphens; start with a letter or number."
  }
}

variable "vpc_cidr" {
  description = "Canonical private IPv4 CIDR for the VPC."
  type        = string
  validation {
    condition = try(
      tonumber(split("/", var.vpc_cidr)[1]) >= 16 &&
      tonumber(split("/", var.vpc_cidr)[1]) <= 28 &&
      split("/", var.vpc_cidr)[0] == cidrhost(var.vpc_cidr, 0) &&
      (
        startswith(cidrhost(var.vpc_cidr, 0), "10.") ||
        startswith(cidrhost(var.vpc_cidr, 0), "192.168.") ||
        (
          startswith(cidrhost(var.vpc_cidr, 0), "172.") &&
          tonumber(split(".", cidrhost(var.vpc_cidr, 0))[1]) >= 16 &&
          tonumber(split(".", cidrhost(var.vpc_cidr, 0))[1]) <= 31
        )
      ), false
    )
    error_message = "vpc_cidr must be a canonical RFC1918 IPv4 network between /16 and /28."
  }
}

variable "availability_zones" {
  description = "At least two distinct AWS availability zones."
  type        = list(string)
  validation {
    condition     = length(var.availability_zones) >= 2 && length(distinct(var.availability_zones)) == length(var.availability_zones)
    error_message = "Provide at least two distinct availability zones."
  }
}

variable "private_subnet_cidrs" {
  description = "One canonical private subnet CIDR in the VPC per availability zone."
  type        = list(string)
  validation {
    condition = (
      length(var.private_subnet_cidrs) == length(var.availability_zones) &&
      length(distinct(var.private_subnet_cidrs)) == length(var.private_subnet_cidrs) &&
      alltrue([for subnet in var.private_subnet_cidrs : try(
        split("/", subnet)[0] == cidrhost(subnet, 0) &&
        tonumber(split("/", subnet)[1]) >= tonumber(split("/", var.vpc_cidr)[1]) &&
        tonumber(split("/", subnet)[1]) <= 28 &&
        cidrhost("${split("/", subnet)[0]}/${split("/", var.vpc_cidr)[1]}", 0) == cidrhost(var.vpc_cidr, 0), false
      )]) &&
      alltrue(flatten([for i, a in var.private_subnet_cidrs : [for j, b in var.private_subnet_cidrs : try(
        i >= j || cidrhost("${split("/", a)[0]}/${min(tonumber(split("/", a)[1]), tonumber(split("/", b)[1]))}", 0) != cidrhost("${split("/", b)[0]}/${min(tonumber(split("/", a)[1]), tonumber(split("/", b)[1]))}", 0), false
      )]]))
    )
    error_message = "Provide one distinct, non-overlapping, canonical /28-or-larger subnet inside the VPC per AZ."
  }
}

variable "flow_logs_bucket_arn" {
  description = "Existing central S3 bucket ARN for VPC flow logs."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^arn:(aws|aws-us-gov|aws-cn):s3:::[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.flow_logs_bucket_arn))
    error_message = "Provide an S3 bucket ARN, without an object path or wildcard."
  }
}

variable "environment" {
  description = "Environment classification."
  type        = string
  validation {
    condition     = contains(["dev", "preprod", "prod"], var.environment)
    error_message = "environment must be dev, preprod or prod."
  }
}

variable "owner" {
  description = "Accountable team identifier."
  type        = string
  nullable    = false
  validation {
    condition     = length(trimspace(var.owner)) > 0
    error_message = "owner cannot be blank."
  }
}

variable "cost_center" {
  description = "Approved chargeback identifier."
  type        = string
  nullable    = false
  validation {
    condition     = length(trimspace(var.cost_center)) > 0
    error_message = "cost_center cannot be blank."
  }
}

variable "data_classification" {
  description = "Data classification for governance and inventory."
  type        = string
  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "Use public, internal, confidential or restricted."
  }
}
