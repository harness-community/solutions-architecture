terraform {
  required_providers {
    harness = {
      source  = "harness/harness"
      version = "~> 0.30"
    }
  }
}

provider "harness" {}

variable "name" {
  type = string
}

variable "org" {
  type    = string
  default = "default"
}

variable "proj" {
  type    = string
  default = "setup"
}

variable "repository_connector" {
  type    = string
  default = "org.harness_community_github"
}

variable "provider_connector" {
  type    = string
  default = "account.oidc759984737373"
}

resource "harness_platform_workspace" "this" {
  name                    = "${var.name}_temp_eks"
  identifier              = "${var.name}_temp_eks"
  org_id                  = var.org
  project_id              = var.proj
  provisioner_type        = "opentofu"
  provisioner_version     = "1.7.0"
  repository              = "https://github.com/harness-community/solutions-architecture"
  repository_branch       = "main"
  repository_path         = "internal/modules/eks"
  cost_estimation_enabled = true
  provider_connector      = var.provider_connector
  repository_connector    = var.repository_connector

  terraform_variable {
    key        = "desired_size"
    value      = "2"
    value_type = "string"
  }

  terraform_variable {
    key        = "name"
    value      = var.name
    value_type = "string"
  }

  environment_variable {
    key        = "HARNESS_ACCOUNT_ID"
    value      = "<+account.identifier>"
    value_type = "string"
  }

  environment_variable {
    key        = "HARNESS_PLATFORM_API_KEY"
    value      = "account.harness_platform_api_key"
    value_type = "secret"
  }
}
