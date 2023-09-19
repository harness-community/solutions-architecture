resource "harness_platform_connector_kubernetes" "sa-cluster" {
  identifier = "sacluster"
  name       = "sa-cluster"

  inherit_from_delegate {
    delegate_selectors = ["sa-gcp"]
  }
}

resource "harness_platform_connector_datadog" "harness-io" {
  identifier = "harnessio"
  name       = "harness-io"

  url                 = "https://app.datadoghq.com/api/"
  application_key_ref = "account.datadogharnessioappkey"
  api_key_ref         = "account.datadogharnessioapikey"
}

resource "harness_platform_connector_artifactory" "harness-artifactory" {
  identifier = "harnessartifactory"
  name       = "harness-artifactory"

  url = "https://harness.jfrog.io/artifactory"
  credentials {
    username     = "automationuser"
    password_ref = "account.artifactoryharnessioapikey"
  }
}

resource "harness_platform_usergroup" "sa_admins" {
  identifier = "sa_admins"
  name       = "sa_admins"

  user_emails = split(",", var.admins)
}

resource "harness_platform_service_account" "internal" {
  identifier = "internal"
  name       = "internal"
  email      = "internal@service.harness.io"
  account_id = var.account_id
}
