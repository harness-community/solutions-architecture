module "pipeline" {
  source = "git@github.com:harness-community/terraform-harness-content.git//modules/pipelines"

  organization_id = module.org_foo.organization_details.id
  project_id      = module.project_appX.project_details.id
  name            = "sample-pipeline"
  yaml_data       = <<EOT
  stages:
    - stage:
        name: Build
        identifier: Build
        description: ""
        type: CI
        spec:
          cloneCodebase: false
          platform:
            os: Linux
            arch: Amd64
          runtime:
            type: Cloud
            spec: {}
          execution:
            steps:
              - step:
                  type: Run
                  name: WhoAmI
                  identifier: WhoAmI
                  spec:
                    shell: Sh
                    command: whoami
  EOT
  tags = {
    role = "sample-pipeline"
  }
}

module "template" {
  source = "git@github.com:harness-community/terraform-harness-content.git//modules/templates"

  name             = "sample-step-template"
  yaml_data        = <<EOT
  spec:
    type: ShellScript
    timeout: 10m
    spec:
      shell: Bash
      onDelegate: true
      source:
        type: Inline
        spec:
          script: |-
            #!/bin/sh
            set -eou pipefail
            set +x

            echo '
            ------------------------------------------------------
            ---- This is a Test Step ----
            ------------------------------------------------------
            '
      environmentVariables: []
      outputVariables: []
  EOT
  template_version = "v1.0.0"
  type             = "Step"
  tags = {
    role = "sample-step"
  }
}
