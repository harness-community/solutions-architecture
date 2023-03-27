locals {
  pipelines = flatten([
    for pipeline in var.repositories : [
      module.pipelines[pipeline].details
    ]

  ])
}

output "details" {
  value       = local.pipelines
  description = "Details for the created Harness Pipelines"
}
