resource "harness_platform_organization" "Harness_Community" {
  identifier  = "Harness_Community"
  name        = "Harness Community"
  description = "For examples that live in the Harness-Community Github repo."
  tags        = ["managed:terraform"]

  lifecycle {
    prevent_destroy = true
  }
}

resource "harness_platform_project" "utilities" {
  identifier = "utilities"
  name       = "utilities"
  org_id     = harness_platform_organization.Harness_Community.id
  tags       = ["managed:terraform"]

  lifecycle {
    prevent_destroy = true
  }
}

resource "harness_platform_project" "setup" {
  identifier = "setup"
  name       = "setup"
  org_id     = harness_platform_organization.Harness_Community.id
  tags       = ["managed:terraform"]

  lifecycle {
    prevent_destroy = true
  }
}

resource "harness_platform_project" "examples" {
  identifier = "examples"
  name       = "examples"
  org_id     = harness_platform_organization.Harness_Community.id
  tags       = ["managed:terraform"]

  lifecycle {
    prevent_destroy = true
  }
}


resource "harness_platform_connector_github" "harness_community_github" {
  identifier = "harness_community_github"
  name       = "harness community"
  tags       = ["managed:terraform"]
  org_id     = harness_platform_organization.Harness_Community.id

  url             = "https://github.com/harness-community"
  connection_type = "Account"
  validation_repo = "solutions-architecture"

  execute_on_delegate = false

  credentials {
    http {
      username  = "solutions-architects"
      token_ref = "org.harnesscommunity_sa_app_token"
    }
  }
  api_authentication {
    github_app {
      installation_id = "40515231"
      application_id  = "314848"
      private_key_ref = "org.harness_solution_architecture_github_app_cert"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "harness_platform_connector_docker" "harness_community_dockerhub" {
  identifier = "harness_community_dockerhub"
  name       = "harness community"
  tags       = ["managed:terraform"]
  org_id     = harness_platform_organization.Harness_Community.id

  type = "DockerHub"
  url  = "https://index.docker.io/v2/"

  execute_on_delegate = false

  credentials {
    username     = "harnesscommunity"
    password_ref = "org.harnesscommunity_dockerhub"
  }

  lifecycle {
    prevent_destroy = true
  }
}