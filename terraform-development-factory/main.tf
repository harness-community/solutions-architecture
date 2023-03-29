module "organization" {
  source  = "harness-community/structure/harness//modules/organizations"
  version = "0.1.2"

  name     = var.organization_name
  existing = var.create_organization ? false : true
}

module "project" {
  source  = "harness-community/structure/harness//modules/projects"
  version = "0.1.2"

  name            = var.project_name
  organization_id = module.organization.details.id
}

module "templates" {
  source  = "harness-community/content/harness//modules/templates"
  version = "0.1.1"

  name            = "Terraform Validation"
  organization_id = module.organization.details.id
  project_id      = module.project.details.id
  yaml_data = templatefile(
    "${path.module}/templates/templates/terraform-deployment.yaml",
    {
      TERRAFORM_FILES_PATH : var.terraform_files
      MAX_CONCURRENCY : var.max_concurrency
    }
  )
  template_version = "v1.0.0"
  type             = "Pipeline"
  tags = {
    role = "Terraform Validation"
  }

}

module "pipelines" {
  source  = "harness-community/content/harness//modules/pipelines"
  version = "0.1.1"

  for_each = {
    for pipeline in var.repositories : (pipeline) => pipeline
  }

  name            = element(split("/", each.value), length(split("/", each.value)) - 1)
  organization_id = module.organization.details.id
  project_id      = module.project.details.id
  yaml_data = templatefile(
    "${path.module}/templates/pipelines/terraform-module-execution.yaml",
    {
      REPOSITORY : each.value
      TEMPLATE_ID : module.templates.details.id
      TEMPLATE_VERSION : module.templates.details.version

    }
  )
  tags = {
    role = "Terraform"
  }

}
module "push_triggers" {
  source  = "harness-community/content/harness//modules/triggers"
  version = "0.1.1"

  for_each = {
    for pipeline in var.repositories : (pipeline) => pipeline
  }

  name            = "Feature Push"
  organization_id = module.organization.details.id
  project_id      = module.project.details.id
  pipeline_id     = module.pipelines[each.value].details.id
  trigger_enabled = var.enable_triggers
  yaml_data = templatefile(
    "${path.module}/templates/triggers/push-trigger.yaml",
    {
      HARNESS_PLATFORM_KEY_SECRET = (
        var.harness_api_key_location != "project"
        ?
        "${var.harness_api_key_location}.${var.harness_api_key_secret}"
        :
        var.harness_api_key_secret
      )
      REPOSITORY : each.value
      PIPELINE_ID : module.pipelines[each.value].details.id
      GITHUB_CONNECTOR : (
        var.github_connector_location != "project"
        ?
        "${var.github_connector_location}.${var.github_connector_id}"
        :
        var.github_connector_id
      )
      GITHUB_USERNAME : var.github_username
      GITHUB_SECRET : (
        var.github_secret_location != "project"
        ?
        "${var.github_secret_location}.${var.github_secret_id}"
        :
        var.github_secret_id
      )
    }
  )
  tags = {
    role = "Terraform"
  }

}

module "pull_request_triggers" {
  source  = "harness-community/content/harness//modules/triggers"
  version = "0.1.1"

  for_each = {
    for pipeline in var.repositories : (pipeline) => pipeline
  }

  name            = "Pull Request"
  organization_id = module.organization.details.id
  project_id      = module.project.details.id
  pipeline_id     = module.pipelines[each.value].details.id
  trigger_enabled = var.enable_triggers
  yaml_data = templatefile(
    "${path.module}/templates/triggers/pull-request-trigger.yaml",
    {
      HARNESS_PLATFORM_KEY_SECRET = (
        var.harness_api_key_location != "project"
        ?
        "${var.harness_api_key_location}.${var.harness_api_key_secret}"
        :
        var.harness_api_key_secret
      )
      REPOSITORY : each.value
      PIPELINE_ID : module.pipelines[each.value].details.id
      GITHUB_CONNECTOR : (
        var.github_connector_location != "project"
        ?
        "${var.github_connector_location}.${var.github_connector_id}"
        :
        var.github_connector_id
      )
      GITHUB_USERNAME : var.github_username
      GITHUB_SECRET : (
        var.github_secret_location != "project"
        ?
        "${var.github_secret_location}.${var.github_secret_id}"
        :
        var.github_secret_id
      )
    }
  )
  tags = {
    role = "Terraform"
  }

}
