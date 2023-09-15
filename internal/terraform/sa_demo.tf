resource "harness_platform_organization" "SA-Demo" {
  identifier  = "SADemo"
  name        = "SA-Demo"
  description = "This place is for customer-facing demos. No testing."
  tags = [
    "demo"
  ]

  lifecycle {
    prevent_destroy = true
  }
}
