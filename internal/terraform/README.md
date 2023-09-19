# internal SA resources

terraform for provisioning the SA Harness account and AWS resources

[See the pipeline here for updates](https://app.harness.io/ng/account/Ompd5rAMSfq97LoZsErwnQ/ci/orgs/Harness_Community/projects/setup/pipelines/solutionsarchitecture_infra/pipeline-studio/?storeType=INLINE)

## aws

### vpc

to use the sa-lab vpc in your own projects you can define the following data resources:

```terraform
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
```

### ecs

to use the ecs cluster created in the harness delegate module use:

```terraform
data "aws_ecs_cluster" "solutions-architecture" {
  cluster_name = "solutions-architecture"
}
```

## foobar

commit here for PR plan runs