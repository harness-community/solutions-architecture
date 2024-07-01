data "aws_region" "current" {}
data "harness_platform_current_account" "current" {}

locals {
  delegate_name = "${var.name}-sales-eks"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.name
  cluster_version = "1.30"

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  vpc_id     = data.aws_vpc.sa-lab.id
  subnet_ids = data.aws_subnets.sa-lab-private.ids

  enable_irsa = true

  enable_cluster_creator_admin_permissions = true

  access_entries = {
    sso = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::759984737373:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AWSPowerUserAccess_c9634c1cd159b7c2"

      policy_associations = {
        example = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  eks_managed_node_groups = {
    example = {
      ami_type       = "AL2_x86_64"
      instance_types = ["t3.medium"]

      min_size     = 2
      max_size     = 5
      desired_size = var.desired_size
    }
  }
}

data "aws_iam_policy_document" "sales_eks" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        module.eks.oidc_provider_arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values = [
        "system:serviceaccount:harness-delegate-ng:${local.delegate_name}"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values = [
        "sts.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "sales_eks" {
  name                 = "${var.name}_sales_eks"
  assume_role_policy   = data.aws_iam_policy_document.sales_eks.json
  max_session_duration = 28800
}

resource "aws_iam_role_policy_attachment" "sales_eks" {
  role       = aws_iam_role.sales_eks.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

data "aws_iam_policy_document" "sales_eks_assumed" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.sales_eks.arn
      ]
    }
  }
}

resource "aws_iam_role" "sales_eks_assumed" {
  name                 = "${var.name}_sales_eks_assumed"
  assume_role_policy   = data.aws_iam_policy_document.sales_eks_assumed.json
  max_session_duration = 28800
}

resource "aws_iam_role_policy_attachment" "sales_eks_assumed" {
  role       = aws_iam_role.sales_eks_assumed.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "harness_platform_connector_kubernetes" "sales_eks" {
  identifier = "${var.name}_sales_eks"
  name       = "${var.name}_sales_eks"

  inherit_from_delegate {
    delegate_selectors = [
      local.delegate_name
    ]
  }
}

resource "harness_platform_connector_kubernetes_cloud_cost" "sales_eks_ccm" {
  identifier = "${var.name}_sales_eks_ccm"
  name       = "${var.name}_sales_eks_ccm"

  features_enabled = ["VISIBILITY", "OPTIMIZATION"]
  connector_ref    = harness_platform_connector_kubernetes.sales_eks.id
}

resource "harness_platform_connector_aws" "sales_eks_aws" {
  identifier = "${var.name}_sales_eks_aws"
  name       = "${var.name}_sales_eks_aws"

  irsa {
    delegate_selectors = [
      local.delegate_name
    ]
    region = "us-west-2"
  }
}

resource "harness_platform_connector_aws" "sales_eks_aws_assumed" {
  identifier = "${var.name}_sales_eks_aws_assumed"
  name       = "${var.name}_sales_eks_aws_assumed"

  irsa {
    delegate_selectors = [
      local.delegate_name
    ]
    region = "us-west-2"
  }
  cross_account_access {
    role_arn = aws_iam_role.sales_eks_assumed.arn
  }
}
