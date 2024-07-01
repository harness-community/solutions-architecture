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

