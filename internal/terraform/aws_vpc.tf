module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "sa-lab"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "type" = "public"
    "vpc"  = "sa-lab"
  }

  private_subnet_tags = {
    "type" = "private"
    "vpc"  = "sa-lab"
  }
}
