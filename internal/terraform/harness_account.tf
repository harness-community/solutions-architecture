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

  user_emails = [
    "loren.yeung@harness.io",
    "brad.thomas@harness.io",
    "emerson.hardisty@harness.io",
    "jayaraman.alagarsamy@harness.io",
    "martin.ansong@harness.io",
    "riley.snyder@harness.io",
    "taylor.shain@harness.io",
    "bogdan.catana@harness.io",
    "charles.crow@harness.io",
    "christopher.suran@harness.io",
    "jeremy.goodrum@harness.io"
  ]
}

resource "harness_platform_service_account" "internal" {
  identifier = "internal"
  name       = "internal"
  email      = "internal@service.harness.io"
  account_id = var.account_id
}
