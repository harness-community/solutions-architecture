data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "this" {
  url = "https://app.harness.io/ng/api/oidc/account/${data.harness_platform_current_account.current.id}"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  # this should be the same for all harness accounts
  thumbprint_list = ["df3c24f9bfd666761b268073fe06d1cc8d4f82a4"]
}

# create the aws iam role
data "aws_iam_policy_document" "this" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.this.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "app.harness.io/ng/api/oidc/account/${data.harness_platform_current_account.current.id}:aud"
      values = [
        "sts.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "this" {
  name                 = "sa_harness_oidc"
  assume_role_policy   = data.aws_iam_policy_document.this.json
  max_session_duration = 28800
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# create the harness aws connector that leverages our oidc role
resource "harness_platform_connector_aws" "oidc" {
  identifier = "oidc${data.aws_caller_identity.current.account_id}"
  name       = "oidc${data.aws_caller_identity.current.account_id}"

  oidc_authentication {
    iam_role_arn       = aws_iam_role.this.arn
    region             = "us-east-1"
    delegate_selectors = []
  }
}
