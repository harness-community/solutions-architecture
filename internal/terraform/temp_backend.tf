terraform {
  backend "http" {
    address = "https://app.harness.io/gateway/iacm/api/orgs/default/projects/default_project/workspaces/awssales/terraform-backend?accountIdentifier=AM8HCbDiTXGQNrTIhNl7qQ"
    username = "harness"
    lock_address = "https://app.harness.io/gateway/iacm/api/orgs/default/projects/default_project/workspaces/awssales/terraform-backend/lock?accountIdentifier=AM8HCbDiTXGQNrTIhNl7qQ"
    lock_method = "POST"
    unlock_address = "https://app.harness.io/gateway/iacm/api/orgs/default/projects/default_project/workspaces/awssales/terraform-backend/lock?accountIdentifier=AM8HCbDiTXGQNrTIhNl7qQ"
    unlock_method = "DELETE"
  }
}
