module "organization" {
  source = "github.com/harness-community/terraform-harness-structure//modules/organizations"

  name     = var.organization_name
  existing = var.create_organization ? false : true
}

module "project" {
  source = "github.com/harness-community/terraform-harness-structure//modules/projects"

  name            = var.project_name
  organization_id = module.organization.organization_details.id
}

module "templates" {
  source = "git@github.com:harness-community/terraform-harness-content.git//modules/templates"

  name            = "Terraform Validation"
  organization_id = module.organization.organization_details.id
  project_id      = module.project.project_details.id
  yaml_data = templatefile(
    "templates/templates/terraform-deployment.yaml",
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
  source = "git@github.com:harness-community/terraform-harness-content.git//modules/pipelines"
  for_each = {
    for pipeline in var.repositories : (pipeline) => pipeline
  }

  name            = element(split("/", each.value), length(split("/", each.value)) - 1)
  organization_id = module.organization.organization_details.id
  project_id      = module.project.project_details.id
  yaml_data = templatefile(
    "templates/pipelines/terraform-module-execution.yaml",
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
  source = "git@github.com:harness-community/terraform-harness-content.git//modules/triggers"
  for_each = {
    for pipeline in var.repositories : (pipeline) => pipeline
  }

  name            = "Feature Push"
  organization_id = module.organization.organization_details.id
  project_id      = module.project.project_details.id
  pipeline_id     = module.pipelines[each.value].details.id
  trigger_enabled = var.enable_triggers
  yaml_data = templatefile(
    "templates/triggers/push-trigger.yaml",
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
  source = "git@github.com:harness-community/terraform-harness-content.git//modules/triggers"
  for_each = {
    for pipeline in var.repositories : (pipeline) => pipeline
  }

  name            = "Pull Request"
  organization_id = module.organization.organization_details.id
  project_id      = module.project.project_details.id
  pipeline_id     = module.pipelines[each.value].details.id
  trigger_enabled = var.enable_triggers
  yaml_data = templatefile(
    "templates/triggers/pull-request-trigger.yaml",
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
