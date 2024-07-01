output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "region" {
  value = data.aws_region.current.name
}

output "delegate_name" {
  value = local.delegate_name
}

output "k8s_connector_id" {
  value = harness_platform_connector_kubernetes.sales_eks.id
}

output "ccm_k8s_connector_id" {
  value = harness_platform_connector_kubernetes_cloud_cost.sales_eks_ccm.id
}

output "aws_connector_id" {
  value = harness_platform_connector_aws.sales_eks_aws.id
}

output "assumed_aws_connector_id" {
  value = harness_platform_connector_aws.sales_eks_aws_assumed.id
}
