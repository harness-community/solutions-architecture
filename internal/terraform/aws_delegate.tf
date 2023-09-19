resource "aws_iam_policy" "delegate_aws_access" {
  name        = "sa_delegate_aws_access"
  description = "Policy for sa harness delegate aws access"

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
       {
           "Sid": "GetSAArtifacts",
           "Effect": "Allow",
           "Action": [
               "s3:*"
           ],
           "Resource": [
              "${aws_s3_bucket.this.arn}",
              "${aws_s3_bucket.this.arn}/*"
           ]
       },
       {
           "Sid": "GetSASecrets",
           "Effect": "Allow",
           "Action": "secretsmanager:GetSecretValue",
           "Resource": "arn:aws:secretsmanager:us-west-2:759984737373:secret:sa/*"
       }
   ]
}
EOF
}

module "delegate" {
  source = "git::https://github.com/harness-community/terraform-aws-harness-delegate-ecs-fargate.git?ref=0.0.10"

  name                      = "sales-ecs"
  cluster_name              = "solutions-architecture"
  harness_account_id        = var.account_id
  delegate_image            = "rssnyder/delegate:latest"
  delegate_token_secret_arn = "arn:aws:secretsmanager:us-west-2:759984737373:secret:sa/account_delegate-NtqV5G"
  delegate_policy_arns = [
    aws_iam_policy.delegate_aws_access.arn,
  ]
  security_groups = [
    module.vpc.default_security_group_id
  ]
  subnets = module.vpc.private_subnets

  manager_host_and_port     = "https://app.harness.io"
  log_streaming_service_url = "https://app.harness.io/log-service/"
}

data "aws_iam_policy_document" "delegate-assumed" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"
      identifiers = [
        module.delegate.aws_iam_role_task
      ]
    }
  }
}

resource "aws_iam_role" "delegate-assumed" {
  name                 = "sa_delegate_assumed_aws_access"
  assume_role_policy   = data.aws_iam_policy_document.delegate-assumed.json
  max_session_duration = 28800
}

resource "aws_iam_role_policy_attachment" "delegate-assumed-AdministratorAccess" {
  role       = aws_iam_role.delegate-assumed.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "harness_platform_variables" "sales-delegate-assumed-role-arn" {
  identifier  = "sales_delegate_assumed_role_arn"
  name        = "sales_delegate_assumed_role_arn"
  description = "an aws role that our ecs delegate can assume for admin access"
  type        = "String"

  spec {
    value_type  = "FIXED"
    fixed_value = aws_iam_role.delegate-assumed.arn
  }
}