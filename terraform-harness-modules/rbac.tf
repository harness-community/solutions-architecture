module "rbac_devops" {
  source = "git@github.com:harness-community/terraform-harness-rbac.git//modules/roles"

  organization_id  = module.org_foo.organization_details.id
  project_id       = module.project_appX.project_details.id
  name             = "devops"
  role_permissions = ["core_environment_access", "core_connector_access"]
}

data "harness_current_account" "current" {}

module "preprod" {
  source = "git@github.com:harness-community/terraform-harness-rbac.git//modules/resource_groups"

  harness_platform_account = data.harness_current_account.current.account_id
  organization_id          = module.org_foo.organization_details.id
  project_id               = module.project_appX.project_details.id
  name                     = "pre-prod"
  resource_group_filters = [
    {
      type = "ENVIRONMENT"
      filters = [
        {
          name = "type"
          values = [
            "PreProduction"
          ]
        }
      ]
    }
  ]
}

module "devops" {
  source = "git@github.com:harness-community/terraform-harness-rbac.git//modules/user_groups"

  organization_id   = module.org_foo.organization_details.id
  project_id        = module.project_appX.project_details.id
  name              = "devops"
  role_id           = module.rbac_devops.role_details.id
  resource_group_id = module.preprod.resource_group_details.id
}

# module "jdoe" {
#   #   source = "git@github.com:harness-community/terraform-harness-rbac.git//modules/user_accounts"
#   source        = "../../git/terraform-harness-rbac/modules/user_accounts"
#   email_address = "riley.snyder+zero@harness.io"
#   user_groups   = [module.devops.user_group_details.id]
#   role_bindings = [{
#     resource_group_id = "_all_account_level_resources"
#     role_id           = "_account_viewer"
#   }]
# }