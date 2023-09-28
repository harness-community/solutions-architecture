# Overview
This project aims to demonstrates with sample inputs on how to use dynamic blocks and modules to reuse Resource group to create resource with different permutation and combinations. Please replace sample inputs with valid ones before running the code.

## Steps.
- `terraform init` - initialises and downloads all the necessary dependencies.
- `terraform plan` - Does a dry run and shows what's getting created/updated/deleted.
- `terraform apply` - Applies the changes.

## Things to know:
- [terraform](https://developer.hashicorp.com/terraform]/[opentofu][https://opentofu.org/docs/)
- terraform [dynamic blocks](https://developer.hashicorp.com/terraform/language/expressions/dynamic-blocks)
- terraform [for_each](https://developer.hashicorp.com/terraform/language/meta-arguments/for_each)
- terraform [count](https://developer.hashicorp.com/terraform/language/meta-arguments/count)

## Dependencies:
### Providers
- harness/harness

## References:
- [Configuring harness provider in terraform](https://registry.terraform.io/providers/harness/harness/latest/docs).
- [Harness Terraform Provider quickstart](https://developer.harness.io/docs/platform/automation/terraform/harness-terraform-provider/)