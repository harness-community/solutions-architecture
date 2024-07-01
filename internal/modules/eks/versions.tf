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
      owner = "riley.snyder@harness.io"
      note  = "should delete at 5pm CST"
      ttl   = "-1"
    }
  }
}

provider "harness" {}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}
