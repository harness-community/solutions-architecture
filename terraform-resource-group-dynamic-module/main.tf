resource "harness_platform_organization" "test-org" {
  name        = var.org_name
  identifier  = var.org_id
  description = "Organization created via terraform"
  tags        = var.org_tag
}

resource "harness_platform_project" "test-project" {
  identifier = "testproject"
  name       = "Test Project"
  org_id     = resource.harness_platform_organization.test-org.identifier
}

module "resource_group" {
  source               = "./module/resource_group"
  count                = length(var.resource_group)
  account_id           = var.account_id
  identifier           = var.resource_group[count.index].identifier
  name                 = var.resource_group[count.index].name
  allowed_scope_levels = var.resource_group[count.index].allowed_scope_levels
  included_scopes      = var.resource_group[count.index].included_scopes
  resource_filter      = var.resource_group[count.index].resource_filter
}