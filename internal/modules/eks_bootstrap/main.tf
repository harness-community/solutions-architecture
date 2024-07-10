terraform {
  required_providers {
    harness = {
      source  = "harness/harness"
      version = "~> 0.30"
    }
  }
}

provider "harness" {}

variable "name" {
  type = string
}

variable "utc_destroy_hr" {
  type = number
  default = 22
}

variable "org" {
  type    = string
  default = "Harness_Community"
}

variable "proj" {
  type    = string
  default = "setup"
}

variable "repository_connector" {
  type    = string
  default = "org.harness_community_github"
}

variable "provider_connector" {
  type    = string
  default = "account.oidc759984737373"
}

resource "harness_platform_workspace" "this" {
  name                    = "${var.name}_temp_eks"
  identifier              = "${var.name}_temp_eks"
  org_id                  = var.org
  project_id              = var.proj
  provisioner_type        = "opentofu"
  provisioner_version     = "1.7.0"
  repository              = "https://github.com/harness-community/solutions-architecture"
  repository_branch       = "main"
  repository_path         = "internal/modules/eks"
  cost_estimation_enabled = true
  provider_connector      = var.provider_connector
  repository_connector    = var.repository_connector

  terraform_variable {
    key        = "desired_size"
    value      = "2"
    value_type = "string"
  }

  terraform_variable {
    key        = "name"
    value      = var.name
    value_type = "string"
  }

  environment_variable {
    key        = "HARNESS_ACCOUNT_ID"
    value      = "<+account.identifier>"
    value_type = "string"
  }

  environment_variable {
    key        = "HARNESS_PLATFORM_API_KEY"
    value      = "account.harness_platform_api_key"
    value_type = "secret"
  }
}

resource "harness_platform_pipeline" "this" {
  identifier = "${var.name}_temp_eks"
  name       = "${var.name}_temp_eks"
  org_id     = var.org
  project_id = var.proj
  yaml = <<-EOT
pipeline:
  name: ${var.name}_temp_eks
  identifier: ${var.name}_temp_eks
  projectIdentifier: ${var.proj}
  orgIdentifier: ${var.org}
  tags: {}
  stages:
    - stage:
        name: provision
        identifier: provision
        description: ""
        type: IACM
        spec:
          workspace: ${var.name}_temp_eks
          execution:
            steps:
              - step:
                  type: IACMTerraformPlugin
                  name: init
                  identifier: init
                  spec:
                    command: init
                  timeout: 10m
              - step:
                  type: IACMTerraformPlugin
                  name: plan
                  identifier: plan
                  spec:
                    command: plan
                  timeout: 10m
              - step:
                  type: IACMApproval
                  name: approve
                  identifier: approve
                  spec:
                    autoApprove: true
                  timeout: 1h
                  when:
                    stageStatus: Success
                    condition: <+trigger.type> != "Scheduled"
              - step:
                  type: IACMTerraformPlugin
                  name: apply
                  identifier: apply
                  spec:
                    command: apply
                  timeout: 1h
                  when:
                    stageStatus: Success
                    condition: <+trigger.type> != "Scheduled"
              - step:
                  type: IACMTerraformPlugin
                  name: destroy
                  identifier: destroy
                  spec:
                    command: destroy
                  timeout: 1h
                  when:
                    stageStatus: Success
                    condition: <+trigger.type> == "Scheduled"
          platform:
            os: Linux
            arch: Amd64
          runtime:
            type: Cloud
            spec: {}
        tags: {}
    - parallel:
        - stage:
            name: metrics server
            identifier: metrics_server
            description: ""
            type: Deployment
            spec:
              deploymentType: Kubernetes
              service:
                serviceRef: metrics_server
              environment:
                environmentRef: development
                deployToAll: false
                infrastructureDefinitions:
                  - identifier: aws_sales
                    inputs:
                      identifier: aws_sales
                      type: KubernetesAws
                      spec:
                        cluster: <+pipeline.stages.provision.spec.execution.steps.apply.output.outputVariables.region>/<+pipeline.stages.provision.spec.execution.steps.apply.output.outputVariables.cluster_name>
                        namespace: kube-system
                        region: <+pipeline.stages.provision.spec.execution.steps.apply.output.outputVariables.region>
              execution:
                steps:
                  - step:
                      name: Rollout Deployment
                      identifier: rolloutDeployment
                      type: K8sRollingDeploy
                      timeout: 10m
                      spec:
                        skipDryRun: false
                        pruningEnabled: false
                rollbackSteps:
                  - step:
                      name: Rollback Rollout Deployment
                      identifier: rollbackRolloutDeployment
                      type: K8sRollingRollback
                      timeout: 10m
                      spec:
                        pruningEnabled: false
            tags: {}
            failureStrategies:
              - onFailure:
                  errors:
                    - AllErrors
                  action:
                    type: StageRollback
            when:
              pipelineStatus: Success
              condition: <+trigger.type> != "Scheduled"
        - stage:
            name: delegate
            identifier: delegate
            description: ""
            type: Deployment
            spec:
              deploymentType: Kubernetes
              service:
                serviceRef: delegate
                serviceInputs:
                  serviceDefinition:
                    type: Kubernetes
                    spec:
                      variables:
                        - name: delegateName
                          type: String
                          value: <+pipeline.stages.provision.spec.execution.steps.apply.output.outputVariables.delegate_name>
                        - name: irsaRoleArn
                          type: String
                          value: <+pipeline.stages.provision.spec.execution.steps.apply.output.outputVariables.irsa_role_arn>
              environment:
                environmentRef: development
                deployToAll: false
                infrastructureDefinitions:
                  - identifier: aws_sales
                    inputs:
                      identifier: aws_sales
                      type: KubernetesAws
                      spec:
                        cluster: <+pipeline.stages.provision.spec.execution.steps.apply.output.outputVariables.region>/<+pipeline.stages.provision.spec.execution.steps.apply.output.outputVariables.cluster_name>
                        namespace: harness-delegate-ng
                        region: <+pipeline.stages.provision.spec.execution.steps.apply.output.outputVariables.region>
              execution:
                steps:
                  - step:
                      name: ns
                      identifier: ns
                      template:
                        templateRef: account.create_namespace
                        versionLabel: 0.0.1
                  - step:
                      name: Rollout Deployment
                      identifier: rolloutDeployment
                      type: K8sRollingDeploy
                      timeout: 10m
                      spec:
                        skipDryRun: false
                        pruningEnabled: false
                rollbackSteps:
                  - step:
                      name: Rollback Rollout Deployment
                      identifier: rollbackRolloutDeployment
                      type: K8sRollingRollback
                      timeout: 10m
                      spec:
                        pruningEnabled: false
            tags: {}
            failureStrategies:
              - onFailure:
                  errors:
                    - AllErrors
                  action:
                    type: StageRollback
            when:
              pipelineStatus: Success
              condition: |
                <+trigger.type> != "Scheduled"
    - stage:
        name: autostopping controller
        identifier: autostopping_controller
        description: ""
        type: Deployment
        spec:
          deploymentType: Kubernetes
          service:
            serviceRef: autostopping_controller
            serviceInputs:
              serviceDefinition:
                type: Kubernetes
                spec:
                  artifacts:
                    primary:
                      primaryArtifactRef: controller
                  variables:
                    - name: connectorId
                      type: String
                      value: <+pipeline.stages.provision.spec.execution.steps.apply.output.outputVariables.ccm_k8s_connector_id>
          environment:
            environmentRef: development
            deployToAll: false
            infrastructureDefinitions:
              - identifier: aws_sales
                inputs:
                  identifier: aws_sales
                  type: KubernetesAws
                  spec:
                    cluster: <+pipeline.stages.provision.spec.execution.steps.apply.output.outputVariables.region>/<+pipeline.stages.provision.spec.execution.steps.apply.output.outputVariables.cluster_name>
                    namespace: harness-autostopping
                    region: <+pipeline.stages.provision.spec.execution.steps.apply.output.outputVariables.region>
          execution:
            steps:
              - step:
                  name: ns
                  identifier: ns
                  template:
                    templateRef: account.create_namespace
                    versionLabel: 0.0.1
              - step:
                  name: Rollout Deployment
                  identifier: rolloutDeployment
                  type: K8sRollingDeploy
                  timeout: 10m
                  spec:
                    skipDryRun: false
                    pruningEnabled: false
            rollbackSteps:
              - step:
                  name: Rollback Rollout Deployment
                  identifier: rollbackRolloutDeployment
                  type: K8sRollingRollback
                  timeout: 10m
                  spec:
                    pruningEnabled: false
        tags: {}
        failureStrategies:
          - onFailure:
              errors:
                - AllErrors
              action:
                type: StageRollback
        when:
          pipelineStatus: Success
          condition: <+trigger.type> != "Scheduled"
EOT
}

resource "harness_platform_triggers" "this" {
  identifier = "${var.name}_temp_eks"
  name       = "${var.name}_temp_eks"
  org_id     = var.org
  project_id = var.proj
  target_id  = "${var.name}_temp_eks"
  yaml       = <<-EOT
trigger:
  name: ${var.name}_temp_eks
  identifier: ${var.name}_temp_eks
  stagesToExecute: []
  enabled: true
  tags: {}
  orgIdentifier: ${var.org}
  projectIdentifier: ${var.proj}
  pipelineIdentifier: ${var.name}_temp_eks
  source:
    type: Scheduled
    spec:
      type: Cron
      spec:
        type: UNIX
        expression: 0 ${var.utc_destroy_hr} * * *
EOT
}
