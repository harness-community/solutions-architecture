module "org_foo" {
  source = "git@github.com:harness-community/terraform-harness-structure.git//modules/organizations?ref=feature/dynamic-lookup-support"

  name        = "Foo"
  description = "resources for buissness unit Foo"
  tags = {
    bu = "foo"
  }
  global_tags = {
    source = "tf_modules_org"
  }
}

module "project_appX" {
  source = "git@github.com:harness-community/terraform-harness-structure.git//modules/projects?ref=feature/dynamic-lookup-support"

  organization_id = module.org_foo.organization_details.id
  name            = "appX"
  description     = "resource for the appX project"
  color           = "#ffffff"
  tags = {
    bu  = module.org_foo.organization_details.id,
    app = "appX"
  }
  global_tags = {
    source = "tf_modules_project"
  }
}

module "variable_appX_cost_center" {
  source = "git@github.com:harness-community/terraform-harness-structure.git//modules/variables?ref=feature/dynamic-lookup-support"

  organization_id = module.org_foo.organization_details.id
  project_id      = module.project_appX.project_details.id
  name            = "cost_center"
  description     = "billing code for application"
  value           = "h768"
  tags = {
    bu  = module.org_foo.organization_details.id,
    app = module.project_appX.project_details.id
  }
  global_tags = {
    source = "tf_modules_variable"
  }
}

module "secret_appX_dockerhub" {
  source = "git@github.com:harness-community/terraform-harness-structure.git//modules/secrets/text?ref=feature/dynamic-lookup-support"

  organization_id = module.org_foo.organization_details.id
  project_id      = module.project_appX.project_details.id
  name            = "dockerhub"
  description     = "dockerhub token"
  value           = "kjsdhf923uewhfslfj-udfsdjh"
  tags = {
    bu  = module.org_foo.organization_details.id,
    app = module.project_appX.project_details.id
  }
  global_tags = {
    source = "tf_modules_variable"
  }
}

module "secret_appX_dockerhub_cert" {
  source = "git@github.com:harness-community/terraform-harness-structure.git//modules/secrets/file?ref=feature/dynamic-lookup-support"

  organization_id = module.org_foo.organization_details.id
  project_id      = module.project_appX.project_details.id
  name            = "dockerhub_cert"
  description     = "dockerhub certificate"
  file_path       = "/Users/rileysnyder/hub.pem"
  tags = {
    bu  = module.org_foo.organization_details.id,
    app = module.project_appX.project_details.id
  }
  global_tags = {
    source = "tf_modules_variable"
  }
}