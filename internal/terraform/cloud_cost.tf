resource "aws_s3_bucket" "this" {
  bucket = "harness-solutions-architecture"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# resource "aws_cur_report_definition" "solutions-architecture" {
#   report_name                = "solutions-architecture"
#   time_unit                  = "HOURLY"
#   format                     = "textORcsv"
#   compression                = "GZIP"
#   additional_schema_elements = ["RESOURCES"]
#   s3_bucket                  = aws_s3_bucket.this.bucket
#   s3_region                  = aws_s3_bucket.this.region
#   s3_prefix                  = "ccm"
#   additional_artifacts       = []
#   report_versioning          = "OVERWRITE_REPORT"
# }

# data "aws_cur_report_definition" "solutions-architecture" {
#   report_name = "solutions-architecture"
# }

# the resource for an aws cur seems to be broken, so lets create on in the console and pretend

locals {
  aws_cur_report_definition_name = "solutions-architecture"
  #   aws_cur_report_definition_bucket = "solutions-architecture"
  #   aws_cur_report_definition_region = "solutions-architecture"
  aws_cur_report_definition_prefix = "ccm"
}

module "ccm" {
  source  = "harness-community/harness-ccm/aws"
  version = "0.1.1"

  s3_bucket_arn = aws_s3_bucket.this.arn
  external_id   = "harness:891928451355:wlgELJ0TTre5aZhzpt8gVA"
  additional_external_ids = [
    "harness:891928451355:V2iSB2gRR_SxBs0Ov5vqCQ"
  ]
  enable_billing          = true
  enable_events           = true
  enable_optimization     = true
  enable_governance       = true
  enable_commitment_read  = true
  enable_commitment_write = true
  governance_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]
  prefix = "sa-"
  secrets = [
    "arn:aws:secretsmanager:us-west-2:759984737373:secret:sa/ca-key.pem-HYlaV4",
    "arn:aws:secretsmanager:us-west-2:759984737373:secret:sa/ca-cert.pem-kq8HQl"
  ]
}

resource "harness_platform_connector_awscc" "sales_aws_cost" {
  identifier = "sales_aws_cost"
  name       = "sales_aws_cost"

  account_id  = data.aws_caller_identity.current.account_id
  report_name = local.aws_cur_report_definition_name
  s3_bucket   = aws_s3_bucket.this.bucket

  features_enabled = [
    "OPTIMIZATION",
    "VISIBILITY",
    "BILLING",
  ]

  cross_account_access {
    role_arn    = module.ccm.cross_account_role
    external_id = module.ccm.external_id
  }
}

resource "harness_platform_connector_azure_cloud_cost" "sales_azure_cost" {
  identifier = "sales_azure_cost"
  name       = "sales_azure_cost"

  tenant_id       = data.azurerm_subscription.current.tenant_id
  subscription_id = data.azurerm_subscription.current.id

  features_enabled = [
    "BILLING",
    "VISIBILITY",
    "OPTIMIZATION"
  ]

  billing_export_spec {
    storage_account_name = azurerm_storage_account.solutions-architecture.name
    container_name       = "ccm"
    directory_name       = "export"
    report_name          = "solutions-architecture"
    subscription_id      = data.azurerm_subscription.current.id
  }
}
