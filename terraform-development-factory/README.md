# Harness Terraform Module Development Solution
A collection of Terraform resources centered around the implementation of the Harness resources to support Terraform Module development

## Goal
The goal of this example will show how to create multiple Harness Pipelines based on a base pipeline template including triggers

## Summary
As the Harness Solutions Architecture team, we have developed and maintained multiple repositories which contain Terraform Modules.  This template will build and deliver the following:

- A new Harness Project in the chosen Organization
- A new Pipeline Template designed to test and validate Terraform executions across numerous Terraform versions
- A new Set of Pipelines based on the number of repositories provided
- A new Set of Pipeline Triggers
    - Push Trigger
    - Pull Request Trigger

## Providers

```
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
| harness_platform_url | Enter the Harness Platform URL.  Defaults to Harness SaaS URL | string | https://app.harness.io/gateway | X |
| harness_platform_account | Enter the Harness Platform Account Number | string | | X |
| harness_platform_key | Enter the Harness Platform API Key for your account | string | | X |
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
