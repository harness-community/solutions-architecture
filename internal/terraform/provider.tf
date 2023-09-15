terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    harness = {
      source  = "harness/harness"
      version = "0.14.11"
    }
  }
  # backend "s3" {
  #   bucket = "harness-solutions-architecture"
  #   key    = "terraform/internal"
  #   region = "us-west-2"
  # }
}

provider "aws" {
  region = "us-west-2"
  default_tags {
    tags = {
      owner = "solutions.architects@harness.io"
      ttl   = "-1"
    }
  }
}

provider "harness" {
  account_id = var.account_id
}
