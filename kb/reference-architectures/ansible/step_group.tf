terraform {
  required_providers {
    harness = {
      source = "harness/harness"
    }
  }
}

resource "harness_platform_template" "ansible_step_group" {
  identifier    = "ansible_step_group"
  name          = "ansible step group"
  version       = "1.0.0"
  is_stable     = true
  template_yaml = <<-EOT
template:
  name: "ansible step group"
  identifier: ansible_step_group
  versionLabel: 1.0.0
  type: StepGroup
  spec:
    stageType: Custom
    stepGroupInfra:
      type: KubernetesDirect
      spec:
        connectorRef: <+input>
        namespace: <+input>
    variables:
      - name: host_file
        type: String
        value: <+input>
        description: ""
        required: false
      - name: playbook
        type: String
        value: <+input>
        description: ""
        required: false
      - name: extra_vars
        type: String
        value: <+input>
        description: ""
        required: false
    steps:
      - step:
          type: GitClone
          name: clone
          identifier: clone
          spec:
            connectorRef: <+input>
            repoName: <+input>
            build:
              type: branch
              spec:
                branch: <+input>
      - step:
          type: Run
          name: playbook
          identifier: playbook
          spec:
            connectorRef: account.dockerhub
            image: pad92/ansible-alpine:9.1.0
            shell: Sh
            command: |-
              # change directory into our cloned git repo
              cd <+execution.steps.ansible.steps.clone.spec.repoName>

              # grab our private ssh key and set the correct permissions
              echo '<+secrets.getValue("pem_file")>' > id_rsa
              chmod 600 id_rsa

              echo '<+secrets.getValue("vault_password")>' > .vault_password

              # if there is an ansible requirements file, install what is required
              if [ -e requirements.yml ]
              then
                  ansible-galaxy install -r requirements.yml
              else
                  echo "no requirements.yml found"
              fi

              # execute the playbook
              ansible-playbook --private-key=id_rsa -i <+execution.steps.ansible.variables.host_file> -e '<+execution.steps.ansible.variables.extra_vars>' <+execution.steps.ansible.variables.playbook>
  EOT
}
