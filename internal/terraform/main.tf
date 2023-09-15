data "harness_platform_organization" "default" {
  identifier = "default"
}

data "harness_platform_project" "default" {
  identifier = "Default_Project_1663065042038"
  org_id     = data.harness_platform_organization.default.id
}
