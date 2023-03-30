# Provider Setup Details
variable "harness_platform_url" {
  type        = string
  description = "[Optional] Enter the Harness Platform URL.  Defaults to Harness SaaS URL"
  default     = "https://app.harness.io/gateway"
}

variable "harness_api_key_secret" {
  type        = string
  description = "[Required] Enter the Harness secret that holds an API key for your account"
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

variable "create_project" {
  type        = bool
  description = "[Optional] Should this execution create a new Project"
  default     = false
}

variable "container_registry" {
  type        = string
  description = "Container Registry to which the image will be saved and stored"
}

variable "container_registry_type" {
  type        = string
  description = "Type of Container Registry to which images will be pushed. Supported Values - azure or docker"

  validation {
    condition = (
      contains(["azure", "docker"], lower(var.container_registry_type))
    )
    error_message = <<EOF
        Validation of an object failed.
            * [Required] Container Registry Type must be one of following:
              - azure
              - docker
        EOF
  }
}

variable "container_registry_connector_ref" {
  type        = string
  description = "Container Registry Connector Reference"
}

variable "kubernetes_connector_ref" {
  type        = string
  description = "Kubernetes Connector Reference"
}

variable "kubernetes_namespace" {
  type        = string
  description = "Kubernetes Namespace within Cluster in which the CI process will build"
}

variable "max_build_concurrency" {
  type        = string
  description = "Maximum number of simultaneous builds to perform"
  default     = 5
}

variable "enable_schedule" {
  type        = bool
  description = "[Optional] Should we enable the execution of this pipeline to run on a schedule?"
  default     = true
}

variable "schedule" {
  type        = string
  description = "[Optional] Cron Format schedule for when and how frequently to schedule this pipeline"
  default     = "0 2 * * *"
}
