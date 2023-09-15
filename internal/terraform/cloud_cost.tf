resource "harness_platform_connector_awscc" "sales_aws_cost" {
  identifier = "sales_aws_cost"
  name       = "sales_aws_cost"

  account_id  = "759984737373"
  report_name = "riley-harness-ccm"
  s3_bucket   = "riley-harness-ccm"

  features_enabled = [
    "OPTIMIZATION",
    "VISIBILITY",
    "BILLING",
  ]

  # using CCM setup from riley's personal Harness account
  cross_account_access {
    role_arn    = "arn:aws:iam::759984737373:role/riley-HarnessCERole"
    external_id = "harness:891928451355:wlgELJ0TTre5aZhzpt8gVA"
  }
}

resource "harness_platform_connector_azure_cloud_cost" "sales_azure_cost" {
  identifier = "sales_azure_cost"
  name       = "sales_azure_cost"

  tenant_id       = "b229b2bb-5f33-4d22-bce0-730f6474e906"
  subscription_id = "e8389fc5-0cb8-44ab-947b-c6cf62552be0"

  features_enabled = [
    "BILLING",
    "VISIBILITY",
    "OPTIMIZATION"
  ]

  # using CCM setup from riley's personal Harness account
  billing_export_spec {
    storage_account_name = "rileysnyderharnessio"
    container_name       = "ccm"
    directory_name       = "export"
    report_name          = "rileysnyderharnessccm"
    subscription_id      = "e8389fc5-0cb8-44ab-947b-c6cf62552be0"
  }
}
