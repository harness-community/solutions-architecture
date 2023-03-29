# Harness Terraform Module Development Solution
A collection of Terraform resources centered around the implementation of the Harness resources to support Terraform Module development

## Goal
The goal of this example will show how to create multiple Harness Pipelines based on a base pipeline template including triggers

## TLDR

```terraform
module "terraform-development-factory" {
  source = "git@github.com:harness-community/solutions-architecture.git//terraform-development-factory?ref=main"

  organization_name         = "terraform-development-factory"
  create_organization       = true
  project_name              = "terraform-development-factory"
  repositories              = ["harness-terraform"]
  terraform_files           = "terraform"
  harness_api_key_location  = "account"
  harness_api_key_secret    = "harness_api_token"
  github_connector_location = "account"
  github_connector_id       = "my_org"
  github_username           = "gh_user"
  github_secret_location    = "account"
  github_secret_id          = "gh_pat"
}
```

## Summary
As the Harness Solutions Architecture team, we have developed and maintained multiple repositories which contain Terraform Modules.  This template will build and deliver the following:

- A new Harness Project in the chosen Organization
- A new Pipeline Template designed to test and validate Terraform executions across numerous Terraform versions
- A new Set of Pipelines based on the number of repositories provided
- A new Set of Pipeline Triggers
    - Push Trigger
    - Pull Request Trigger

## Providers

This module requires that the calling template has defined the [Harness Provider - Docs](https://registry.terraform.io/providers/harness/harness/latest/docs) authentication.

### Example setup of the Harness Provider Authentication with environment variables

You can also set up authentication with Harness through environment variables. To do this set the following items in your environment:
- HARNESS_ACCOUNT_ID: Harness Platform Account Number
- HARNESS_PLATFORM_API_KEY: Harness Platform API Key for your account

_Note: The use of the HARNESS_ENDPOINT environment variable is not used as the variable `harness_platform_url` is a required input for some of the resource creation steps and cannot be read within the execution except by explicit declaration of the variables value_

### Example setup of the Harness Provider

```terraform
# Provider Setup Details
variable "harness_platform_url" {
  type        = string
  description = "[Optional] Enter the Harness Platform URL.  Defaults to Harness SaaS URL"
  default     = "https://app.harness.io/gateway"
}
variable "harness_platform_account" {
  type        = string
  description = "[Required] Enter the Harness Platform Account Number"
  default     = null # If Not passed, then the ENV HARNESS_ACCOUNT_ID will be used
  sensitive   = true
}
variable "harness_platform_key" {
  type        = string
  description = "[Required] Enter the Harness Platform API Key for your account"
  default     = null # If Not passed, then the ENV HARNESS_PLATFORM_API_KEY will be used
  sensitive   = true
}
provider "harness" {
  endpoint         = var.harness_platform_url
  account_id       = var.harness_platform_account
  platform_api_key = var.harness_platform_key
}
```

### Terraform required providers declaration

```terraform
terraform {
  required_providers {
    harness = {
      source  = "harness/harness"
      version = ">= 0.14"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9.1"
    }
  }
}
```

## Requirements
The following items will be required to be preconfigured in our Harness Account
- Harness Service Account with an API Key
- Harness API Key stored in a Harness Secret
- GitHub Connector with access to repositories
- GitHub Token stored in a Harness Secret

_Note: Additional tools required on the delegate to support Terraform provisioning_
- git
- [TFENV Utility](https://github.com/tfutils/tfenv) to manage the different Terraform versions
```
# Install and Configure TFENV in a Harness Delegate
git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv
ln -s ~/.tfenv/bin/* /usr/local/bin
tfenv install latest
tfenv use latest
```
_Note: About testing your Terraform repositories_
This Terraform Template will create one or more Harness Pipelines based on the provided list of repositories.  The pipeline will look for a file called `.terraform_version` in the root of the repository which contains a list of Terraform versions to verify.
- Each version should be declared on a new line with the exact Terraform version to be validated
- If the file doesn't exist, the pipeline will automatically run the terraform validation using the latest version returned from [TFENV Utility](https://github.com/tfutils/tfenv)

_Example Terraform Versions File_
```
1.2.9
1.3.9
1.4.0
1.4.2
```

## Variables

| Name | Description | Type | Default Value | Mandatory |
| --- | --- | --- | --- | --- |
| organization_name | Provide an organization name.  Must be two or more characters | string | | X |
| project_name | Provide an project name.  Must be two or more characters | string | | X |
| repositories | List of Repositories for which to configure and create pipelines | list(string) | | X |
| terraform_files | File path location where the Terraform files will be sourced for the repository | string | | X |
| max_concurrency | Maximum concurrency of Terraform Version validations | string | 4 | |
| enable_triggers | Should we enable the Triggers created by this template | bool | | X |
| harness_api_key_location | Choose the Secret Location within Harness.  Supported values are account, org, or project. | string | | X |
| harness_api_key_secret | Provide an existing Harness Secret containing the Harness API Key for the pipelines | string | | X |
| github_connector_location | Choose the Connector Location within Harness.  Supported values are account, org, or project. | string | | X |
| github_connector_id | Name of the GitHub Connector to use | string | | X |
| github_username | Username for the GitHub Connection | string | | X |
| github_secret_location | Choose the Secret Location within Harness.  Supported values are account, org, or project. | string | | X |
| github_secret_id | Name of the GitHub secret to use | string | | X |

## Terraform TFVARS
Included in this repository is a `terraform.tfvars.example` file with a sample file that can be used to construct your own `terraform.tfvars` file.

- Save a copy of the file as `terraform.tfvars`
- Update the variable values listed in the new TFVAR file

## Outputs
| Name | Description | Value |
| --- | --- | --- |
| details | Details for the created Harness pipelines | Map containing details of created pipeline |

## Contributing
A complete [Contributors Guide](../CONTRIBUTING.md) can be found in this repository

## Authors
Module is maintained by Harness, Inc

## License

MIT License. See [LICENSE](../LICENSE) for full details.
