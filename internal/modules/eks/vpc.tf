data "aws_vpc" "default" {
  default = true
}

data "aws_vpc" "sa-lab" {
  tags = {
    Name = "sa-lab"
  }
}

data "aws_security_group" "sa-lab-default" {
  vpc_id = data.aws_vpc.sa-lab.id

  filter {
    name   = "description"
    values = ["default VPC security group"]
  }
}

data "aws_subnets" "sa-lab-private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.sa-lab.id]
  }

  tags = {
    type = "private"
  }
}

data "aws_subnets" "sa-lab-public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.sa-lab.id]
  }

  tags = {
    type = "public"
  }
}
