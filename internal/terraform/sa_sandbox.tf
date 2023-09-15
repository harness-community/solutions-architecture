resource "harness_platform_organization" "SA-Sandbox" {
  identifier  = "SASandbox"
  name        = "SA-Sandbox"
  description = "Testing and Scratch Pad Area for SA's and SE's"
  tags = [
    "sandbox"
  ]
}
