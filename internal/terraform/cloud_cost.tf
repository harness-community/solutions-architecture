resource "aws_s3_bucket" "solutions-architecture" {
  bucket = "solutions-architecture"

  tags = {
    Owner = "sa@harness.io"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "solutions-architecture" {
  bucket = aws_s3_bucket.solutions-architecture.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "solutions-architecture" {
  bucket = aws_s3_bucket.solutions-architecture.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_cur_report_definition" "solutions-architecture" {
  report_name                = "solutions-architecture"
  time_unit                  = "HOURLY"
  format                     = "textORcsv"
  compression                = "GZIP"
  additional_schema_elements = ["RESOURCES"]
  s3_bucket                  = aws_s3_bucket.solutions-architecture.bucket
  s3_region                  = aws_s3_bucket.solutions-architecture.region
  s3_prefix                  = "ccm"
  additional_artifacts       = []
  report_versioning          = "OVERWRITE_REPORT"
}

module "ccm" {
  source  = "harness-community/harness-ccm/aws"
  version = "0.1.1"

  s3_bucket_arn = aws_s3_bucket.solutions-architecture.arn
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

  account_id  = "759984737373"
  report_name = aws_cur_report_definition.solutions-architecture.report_name
  s3_bucket   = aws_s3_bucket.solutions-architecture.bucket

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
