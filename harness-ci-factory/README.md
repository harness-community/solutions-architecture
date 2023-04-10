# Harness CI Image Factory

A collection of Terraform resources centered around the implementation of the Harness CI Factory Pipeline to support managing Harness CI Container Images

## TLDR

_Note: The use of this module requires that the calling template also includes a Harness Terraform Provider configuration.  Learn [How to setup the Harness Terraform Provider](#providers)_

```terraform
module "harness-ci-factory" {
  source = "git@github.com:harness-community/solutions-architecture.git//harness-ci-factory?ref=main"

  harness_api_key_secret           = "account.harness_api_token"
  organization_name                = "harness-ci-factory"
  create_organization              = true
  project_name                     = "harness-ci-factory"
  create_project                   = true
  container_registry               = "registry.example.com"
  container_registry_type          = "docker"
  container_registry_connector_ref = "account.registry_example_com"
  kubernetes_connector_ref         = "account.example_cluster"
  kubernetes_namespace             = "harnesscifactory"
  max_build_concurrency            = 5
  enable_schedule                  = false
  schedule                         = "0 2 * * *"
}
```

After pulling, building, and pushing the images to your registry you will need to edit the `harnessImage` docker connector in your Harness account to point that the registry you pushed to using this module (specified by the `container_registry` input).

![image](https://user-images.githubusercontent.com/7338312/228593992-c5ad744b-ee5d-4dd2-b68a-0fdf968c90d6.png)

If you do not want to edit this default connector, you can optionally set `modify_default_image_config` to false. Then in your CI stage under `infrastructure`>`advanced`>`override image connector` you would select the image connector where you saved the Harness images (`container_registry_connector_ref`).

## Summary

As the Harness Solutions Architecture team, we have developed a pipeline to manage the ingestion of Harness CI Build images into a customer maintained Container Registry.  This template will build and deliver the following:

- An optional new Harness Organization
- An optional new Harness Project in the chosen Organization
- A new Stage Template designed to retrieve and compare the list of images to generate a new list from which to build
- A new Stage Template designed to create a pass-thru Dockerfile and push to the chose `container_registry_type`
- A new Pipeline used to collect, build, and push the Harness CI images into the selected container registry
- A new Pipeline trigger to schedule the repeated execution of the Pipeline

_Note: The created pipeline has a built-in retry mechanism which will automatically retrigger the pipeline.  This execution is designed to only run once and will automatically invoke the execution at the end of the run when it is determined that not all the images updated successfully._


## Providers

This module requires that the calling template has defined the [Harness Provider - Docs](https://registry.terraform.io/providers/harness/harness/latest/docs) authentication.

### Example setup of the Harness Provider Authentication with environment variables

You can also set up authentication with Harness through environment variables. To do this set the following items in your environment:
- HARNESS_ACCOUNT_ID: Harness Platform Account Number
- HARNESS_PLATFORM_API_KEY: Harness Platform API Key for your account

_Note: The use of the HARNESS_ENDPOINT environment variable is not used as the variable `harness_platform_url` is a required input for some of the resource creation steps and cannot be read within the execution except by explicit declaration of the variables value_

### Example setup of the Harness Provider

```
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
- Kubernetes Connector with a chosen namespace for execution of the Build Pods
- Container Registry Connector of a supported type

## Variables

_Note: When providing `_ref` values, please ensure that these are prefixed with the correct location details depending if the connector is at the Organization (org.) or Account (account.) levels.  For Project Connectors, nothing else is required excluding the reference ID for the connector._

| Name | Description | Type | Default Value | Mandatory |
| --- | --- | --- | --- | --- |
| harness_platform_url | Enter the Harness Platform URL.  Defaults to Harness SaaS URL | string | https://app.harness.io/gateway | X |
| harness_api_key_secret | Enter the Harness secret that holds an API key for your account | string | | X |
| organization_name | Provide an organization name.  Must be two or more characters | string | | X |
| create_organization | Should this execution create a new Organization | bool | false | X |
| project_name | Provide an project name.  Must be two or more characters | string | | X |
| create_project | Should this execution create a new Project | bool | false | X |
| container_registry | Registry to which the image will be saved and stored | string | | X |
| container_registry_type | Registry Type to which images will be pushed. Supported Values - azure or docker | string | | X |
| container_registry_connector_ref | Container Registry Connector Reference (see above _note:_)| string | | X |
| kubernetes_connector_ref | Kubernetes Connector Reference (see above _note:_) | string | | X |
| kubernetes_namespace |  Namespace within Cluster in which the CI process will build | string | | X |
| max_build_concurrency |  number of simultaneous builds to perform | string | 5 | X |
| enable_schedule | Should we enable the execution of this pipeline to run on a schedule? | bool | true | |
| schedule | Cron Format schedule for when and how frequently to schedule this pipeline | string | "0 2 * * *" | |
| modify_default_image_config | Update the Harness Platform to use the newly pushed images as the default versions when running CI pipelines. (requires modification of the harnessImages docker connector) | bool | true | |


## Terraform TFVARS

Included in this repository is a `terraform.tfvars.example` file with a sample file that can be used to construct your own `terraform.tfvars` file.

- Save a copy of the file as `terraform.tfvars`
- Update the variable values listed in the new TFVAR file

## Outputs

| Name | Description | Value |
| --- | --- | --- |
| pipeline | Details for the created Harness pipeline | Map containing details of created pipeline |

## Contributing

A complete [Contributors Guide](../CONTRIBUTING.md) can be found in this repository

## Authors

Module is maintained by Harness, Inc

## License

MIT License. See [LICENSE](../LICENSE) for full details.
