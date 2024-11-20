module "dev" {
  source  = "harness-community/delivery/harness//modules/environments"
  version = "0.1.0"

  organization_id = module.org_foo.organization_details.id
  project_id      = module.project_appX.project_details.id
  name            = "dev"
  type            = "nonprod"
  yaml_render     = false
  yaml_data       = <<EOT
environment:
  name: dev
  identifier: dev
  projectIdentifier: ${module.project_appX.project_details.id}
  orgIdentifier: ${module.org_foo.organization_details.id}
  description: Harness Environment created via Terraform
  type: PreProduction
  EOT
}

module "dev_k8s" {
  source  = "harness-community/delivery/harness//modules/infrastructures"
  version = "0.1.0"

  organization_id = module.org_foo.organization_details.id
  project_id      = module.project_appX.project_details.id
  name            = "k8s"
  environment_id  = module.dev.environment_details.id
  type            = "KubernetesDirect"
  deployment_type = "Kubernetes"
  yaml_data       = <<EOT
spec:
  connectorRef: ${module.dev_k8s_delegate.connector_details.id}
  namespace: appx
  releaseName: release-<+INFRA_KEY>
  EOT
}

module "appX" {
  source  = "harness-community/delivery/harness//modules/services"
  version = "0.1.0"

  organization_id = module.org_foo.organization_details.id
  project_id      = module.project_appX.project_details.id
  name            = "appX"
  yaml_render     = false
  yaml_data       = <<EOT
service:
  name: appX
  identifier: appx
  tags: {}
  serviceDefinition:
    type: Kubernetes
    spec:
      manifests:
        - manifest:
            identifier: template
            type: K8sManifest
            spec:
              store:
                type: Github
                spec:
                  connectorRef: ${module.github.connector_details.id}
                  gitFetchType: Branch
                  paths:
                    - deployment.yaml
                  repoName: rssnyder/template
                  branch: main
              valuesPaths:
                - values.yaml
              skipResourceVersioning: false
      artifacts:
        primary:
          primaryArtifactRef: <+input>
          sources:
            - spec:
                connectorRef: account.dockerhub
                imagePath: library/nginx
                tag: <+input>
              identifier: nginx
              type: DockerRegistry
      variables:
        - name: port
          type: String
          description: ""
          value: <+input>
          default: "80"
        - name: replicas
          type: String
          description: ""
          value: <+input>
          default: "1"
  EOT
}
