module "organization" {
  source  = "harness-community/structure/harness//modules/organizations"
  version = "0.1.3"

  name     = var.organization_name
  existing = var.create_organization ? false : true
}

module "project" {
  source  = "harness-community/structure/harness//modules/projects"
  version = "0.1.3"

  name            = var.project_name
  organization_id = module.organization.details.id
  existing        = var.create_project ? false : true
}

module "gather-harness-ci-images-template" {
  source  = "harness-community/content/harness//modules/templates"
  version = "0.1.1"

  name             = "Gather Harness CI Images"
  organization_id  = module.organization.details.id
  project_id       = module.project.details.id
  template_version = "v1.0.0"
  type             = "Stage"
  yaml_data = templatefile(
    "${path.module}/templates/templates/gather-harness-ci-image-list.yaml",
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
  source  = "harness-community/content/harness//modules/templates"
  version = "0.1.1"

  name             = "Build and Push Harness CI Standard Images"
  organization_id  = module.organization.details.id
  project_id       = module.project.details.id
  template_version = "v1.0.0"
  type             = "Stage"
  yaml_data = templatefile(
    "${path.module}/templates/templates/${lookup(local.build_push_target, var.container_registry_type, "MISSING-REGISTRY-TEMPLATE")}",
    {
      REGISTRY_NAME : var.container_registry
      MAX_CONCURRENCY : var.max_build_concurrency
      CONTAINER_REGISTRY_CONNECTOR : var.container_registry_connector_ref
      KUBERNETES_CONNECTOR_REF : var.kubernetes_connector_ref
      KUBERNETES_NAMESPACE : var.kubernetes_namespace
      HARNESS_IMAGE_CONNECTOR : var.external_image_connector_ref
    }
  )
  tags = {
    role = "harness-ci-image-factory"
  }

}

module "harness-ci-image-factory" {
  source  = "harness-community/content/harness//modules/pipelines"
  version = "0.1.1"

  name            = "Harness CI Image Factory"
  description     = "This pipeline will find, build, push, and configure Harness Platform to retrieve CI build images from a custom registry"
  organization_id = module.organization.details.id
  project_id      = module.project.details.id
  yaml_data = templatefile(
    "${path.module}/templates/pipelines/harness-ci-image-factory.yaml",
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
      MODIFY_DEFAULT : tostring(var.modify_default_image_config)
    }
  )
  tags = {
    role = "harness-ci-image-factory"
  }

}

module "harness-ci-image-factory-cleanup" {
  source  = "harness-community/content/harness//modules/pipelines"
  version = "0.1.1"

  name            = "Harness CI Image Factory - Reset Images to Harness"
  description     = "This pipeline will reset the custom images back to the default Harness Platform values"
  organization_id = module.organization.details.id
  project_id      = module.project.details.id
  yaml_data = templatefile(
    "${path.module}/templates/pipelines/harness-ci-image-reset.yaml",
    {
      HARNESS_URL : var.harness_platform_url
      HARNESS_API_KEY_SECRET : var.harness_api_key_secret
      GATHER_SCAN_TEMPLATE : module.gather-harness-ci-images-template.details.id
    }
  )
  tags = {
    role = "harness-ci-image-factory"
  }

}

module "pipeline-execution-schedule" {
  source  = "harness-community/content/harness//modules/triggers"
  version = "0.1.1"

  name            = "Retrieve and Build Images"
  organization_id = module.organization.details.id
  project_id      = module.project.details.id
  pipeline_id     = module.harness-ci-image-factory.details.id
  trigger_enabled = var.enable_schedule
  yaml_data = templatefile(
    "${path.module}/templates/triggers/retrieve-and-build-images.yaml",
    {
      SCHEDULE : var.schedule
      REGISTRY_NAME : var.container_registry
    }
  )
  tags = {
    role = "harness-ci-image-factory"
  }

}
