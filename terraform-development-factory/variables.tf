# Provider Setup Details
variable "harness_platform_url" {
  type        = string
  description = "[Optional] Enter the Harness Platform URL.  Defaults to Harness SaaS URL"
  default     = "https://app.harness.io/gateway"
}

variable "harness_platform_account" {
  type        = string
  description = "[Required] Enter the Harness Platform Account Number"
  sensitive   = true
}

variable "harness_platform_key" {
  type        = string
  description = "[Required] Enter the Harness Platform API Key for your account"
  sensitive   = true
}

variable "organization_name" {
  type        = string
  description = "[Required] Provide an organization name.  Must be two or more characters"
}

variable "create_organization" {
  type        = bool
  description = "[Optional] Should this execution create a new Organization"
  default     = false
}

variable "project_name" {
  type        = string
  description = "[Required] Provide an project name.  Must be two or more characters"
}

variable "repositories" {
  type        = list(string)
  description = "[Required] List of Repositories for which to configure and create pipelines"
}

variable "terraform_files" {
  type        = string
  description = "[Required] File path location where the Terraform files will be sourced for the repository"
}

variable "max_concurrency" {
  type        = string
  description = "[Optional] Maximum concurrency of Terraform Version validations."
  default     = 4
}

variable "enable_triggers" {
  type        = bool
  description = "[Optional] Should we enable the Triggers created by this template"
  default     = false
}

variable "harness_api_key_location" {
  type        = string
  description = "[Required] Choose the Secret Location within Harness.  Supported values are account, org, or project."

  validation {
    condition = (
      contains(["account", "org", "project"], var.harness_api_key_location)
    )
    error_message = <<EOF
        Validation of an object failed.
            * [Required] Choose the Secret Location within Harness.  Supported values are account, org, or project.
        EOF
  }
}

variable "harness_api_key_secret" {
  type        = string
  description = "[Required] Provide an existing Harness Secret containing the Harness API Key for the pipelines"
}

variable "github_connector_location" {
  type        = string
  description = "[Required] Choose the Connector Location within Harness.  Supported values are account, org, or project."

  validation {
    condition = (
      contains(["account", "org", "project"], var.github_connector_location)
    )
    error_message = <<EOF
        Validation of an object failed.
            * [Required] Choose the Connector Location within Harness.  Supported values are account, org, or project.
        EOF
  }
}

variable "github_connector_id" {
  type        = string
  description = "[Required] Name of the GitHub Connector to use"
}

variable "github_username" {
  type        = string
  description = "[Required] Username for the GitHub Connection"
}

variable "github_secret_location" {
  type        = string
  description = "[Required] Choose the Secret Location within Harness.  Supported values are account, org, or project."

  validation {
    condition = (
      contains(["account", "org", "project"], var.github_secret_location)
    )
    error_message = <<EOF
        Validation of an object failed.
            * [Required] Choose the Secret Location within Harness.  Supported values are account, org, or project.
        EOF
  }
}
variable "github_secret_id" {
  type        = string
  description = "[Required] Name of the GitHub secret to use"
}
