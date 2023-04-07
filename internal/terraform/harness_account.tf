resource "harness_platform_variables" "sales_aws_delegate_role" {
  identifier = "sales_aws_delegate_role"
  name       = "sales_aws_delegate_role"
  type       = "String"
  spec {
    value_type  = "FIXED"
    fixed_value = aws_iam_role.delegate-assumed.arn
  }
}