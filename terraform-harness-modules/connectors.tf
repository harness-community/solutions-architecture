module "dev_k8s_delegate" {
  source = "git@github.com:harness-community/terraform-harness-connectors.git//modules/kubernetes/cluster"

  organization_id    = module.org_foo.organization_details.id
  project_id         = module.project_appX.project_details.id
  name               = "dev_k8s"
  delegate_selectors = ["minikube"]
}

module "github" {
  source = "git@github.com:harness-community/terraform-harness-connectors.git//modules/scms/github"

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