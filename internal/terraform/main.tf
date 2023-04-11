data "harness_platform_organization" "default" {
  identifier = "default"
}

data "harness_platform_project" "default" {
  identifier = "Default_Project_1663065042038"
  org_id     = data.harness_platform_organization.default.id
}

resource "harness_platform_organization" "SA-Demo" {
  identifier  = "SADemo"
  name        = "SA-Demo"
  description = "This place is for customer-facing demos. No testing."
  tags = [
    "demo"
  ]
}

resource "harness_platform_organization" "SA-Sandbox" {
  identifier  = "SASandbox"
  name        = "SA-Sandbox"
  description = "Testing and Scratch Pad Area for SA's and SE's"
  tags = [
    "sandbox"
  ]
}