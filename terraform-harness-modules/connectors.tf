module "dev_k8s_delegate" {
  source  = "harness-community/connectors/harness//modules/kubernetes/cluster"
  version = "0.1.1"

  organization_id    = module.org_foo.organization_details.id
  project_id         = module.project_appX.project_details.id
  name               = "dev_k8s"
  delegate_selectors = ["minikube"]
}

module "github" {
  source  = "harness-community/connectors/harness//modules/scms/github"
  version = "0.1.1"

  organization_id = module.org_foo.organization_details.id
  project_id      = module.project_appX.project_details.id
  name            = "rssnyder"
  url             = "https://github.com/rssnyder"
  github_credentials = {
    type            = "http"
    username        = "rssnyder"
    secret_location = "account"
    password        = "gh_pat"
  }
}
