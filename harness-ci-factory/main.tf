module "organization" {
  source = "github.com/harness-community/terraform-harness-structure//modules/organizations"

  name     = var.organization_name
  existing = var.create_organization ? false : true
}

module "project" {
  source = "github.com/harness-community/terraform-harness-structure//modules/projects"

  name            = var.project_name
  organization_id = module.organization.organization_details.id
  existing        = var.create_project ? false : true
}

module "gather-harness-ci-images-template" {
  source = "git@github.com:harness-community/terraform-harness-content.git//modules/templates"

  name             = "Gather Harness CI Images"
  organization_id  = module.organization.organization_details.id
  project_id       = module.project.project_details.id
  template_version = "v1.0.0"
  type             = "Stage"
  yaml_data = templatefile(
    "templates/templates/gather-harness-ci-image-list.yaml",
    {
      HARNESS_URL : var.harness_platform_url
      HARNESS_API_KEY_SECRET : var.harness_api_key_secret
    }
  )
  tags = {
    role = "harness-ci-image-factory"
  }

}

module "build-push-template" {
  source = "git@github.com:harness-community/terraform-harness-content.git//modules/templates"

  name             = "Build and Push Harness CI Standard Images"
  organization_id  = module.organization.organization_details.id
  project_id       = module.project.project_details.id
  template_version = "v1.0.0"
  type             = "Stage"
  yaml_data = templatefile(
    "templates/templates/${lookup(local.build_push_target, var.container_registry_type, "MISSING-REGISTRY-TEMPLATE")}",
    {
      REGISTRY_NAME : var.container_registry
      MAX_CONCURRENCY : var.max_build_concurrency
      CONTAINER_REGISTRY_CONNECTOR : var.container_registry_connector_ref
      KUBERNETES_CONNECTOR_REF : var.kubernetes_connector_ref
      KUBERNETES_NAMESPACE : var.kubernetes_namespace
    }
  )
  tags = {
    role = "harness-ci-image-factory"
  }

}

module "harness-ci-image-factory" {
  source = "git@github.com:harness-community/terraform-harness-content.git//modules/pipelines"

  name            = "Harness CI Image Factory"
  organization_id = module.organization.organization_details.id
  project_id      = module.project.project_details.id
  yaml_data = templatefile(
    "templates/pipelines/harness-ci-image-factory.yaml",
    {
      HARNESS_URL : var.harness_platform_url
      HARNESS_API_KEY_SECRET : var.harness_api_key_secret
      GATHER_SCAN_TEMPLATE : module.gather-harness-ci-images-template.details.id
      BUILD_PUSH_TEMPLATE : module.build-push-template.details.id
      REGISTRY_NAME : var.container_registry
      MAX_CONCURRENCY : var.max_build_concurrency
      CONTAINER_REGISTRY_CONNECTOR : var.container_registry_connector_ref
      KUBERNETES_CONNECTOR_REF : var.kubernetes_connector_ref
      KUBERNETES_NAMESPACE : var.kubernetes_namespace
    }
  )
  tags = {
    role = "harness-ci-image-factory"
  }

}

module "pipeline-execution-schedule" {
  source = "git@github.com:harness-community/terraform-harness-content.git//modules/triggers"

  name            = "Retrieve and Build Images"
  organization_id = module.organization.organization_details.id
  project_id      = module.project.project_details.id
  pipeline_id     = module.harness-ci-image-factory.details.id
  trigger_enabled = var.enable_schedule
  yaml_data = templatefile(
    "templates/triggers/retrieve-and-build-images.yaml",
    {
      SCHEDULE : var.schedule
      REGISTRY_NAME : var.container_registry
    }
  )
  tags = {
    role = "harness-ci-image-factory"
  }

}
