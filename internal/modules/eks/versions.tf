terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    harness = {
      source  = "harness/harness"
      version = "~> 0.30"
    }
  }
}

provider "aws" {
  region = "us-west-2"
  default_tags {
    tags = {
      owner = "implementationengineering@harness.io"
      note  = "should delete at 5pm CST"
      ttl   = "24h"
    }
  }
}

provider "harness" {}
