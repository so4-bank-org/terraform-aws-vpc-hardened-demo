module "vpc" {
  source = "../.."

  name                 = "demo-private-vpc"
  vpc_cidr             = "10.42.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  private_subnet_cidrs = ["10.42.1.0/24", "10.42.2.0/24"]
  flow_logs_bucket_arn = "arn:aws:s3:::replace-with-approved-flow-log-bucket"

  environment         = "dev"
  owner               = "example-platform-team"
  cost_center         = "DEMO-001"
  data_classification = "internal"
}
