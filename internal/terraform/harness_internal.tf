resource "harness_platform_project" "internal" {
  identifier = "internal"
  name       = "internal"
  org_id     = data.harness_platform_organization.default.id
}

###

resource "harness_platform_connector_github" "harness_community" {
  identifier = "harness_community"
  name       = "harness_community"

  org_id     = data.harness_platform_organization.default.id
  project_id = harness_platform_project.internal.id

  url             = "https://github.com/harness_community"
  connection_type = "Account"
  validation_repo = "solutions-architecture"

  # once we support github app, move to that
  credentials {
    http {
      username  = "rssnyder"
      token_ref = "account.riley_delete_me"
    }
  }

  api_authentication {
    token_ref = "account.riley_delete_me"
  }
}