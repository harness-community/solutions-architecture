# Harness Template Design Best Practices

Harness templates serve as a powerful tool to standardize deployment patterns, streamline processes, and eliminate duplicate efforts. This guide will outline a set of best practices to utilize Harness templates more effectively.

## Variables

Templates should have a well-defined interface for expected inputs and should not rely on assumptions that certain variables exist in a pipeline where they will be used. For instance, when defining a step or stage template, avoid referencing any pipeline level variables (such as `<+pipeline.variables.X>`). This practice can break encapsulation and may not clearly communicate to the template users that their pipeline requires these variables to be defined. This rule also applies to usung stage-level variables inside of a step template (i.e. `<+stage.variables.X>`).

Instead, it's advisable to use **runtime inputs** (`<+input>`), which expose necessary variables to those using your template. Additionally, Harness provides numerous built-in variables, such as <+env.name> and many others, that can be incredibly useful. However, as a best practice, limit the usage of these inside templates as much as reasonably possible. Rather, delegate the decision to the template user. This allows for greater flexibility and adaptability when applying the template to different use-cases.

The following examples will clarify how to optimally use various types of templates.

### Runtime Inputs

When marking a field or variable as `<+input>` always try and provide a default value. 

### Descriptions

Always aim to provide detailed descriptions of variables when possible. Additionally, use the description field on the template itself to offer further guidance on its usage. This not only enhances clarity but also facilitates efficient and correct usage of the templates by the end-users.

## Step Templates

Step templates serve as an efficient way to encapsulate common tasks that can be reused across multiple pipelines. Make sure to mark all configurable fields as `<+input>`. With shell scripts specifically, you should define input variables as `<+input>` and then reference them in the script using `${SOME_VAR}` for bash or `$Env:SOME_VAR` for PowerShell.

Below are examples of proper and improper usage:

**Bad**

In this example, a pipeline level variable is directly referenced. This practice makes it unclear for the template users about the required variables.

```yaml
template:
  name: Example Step Template - Bad
  identifier: Example_Step_Template_Bad
  type: Step
  spec:
    type: ShellScript
    spec:
      shell: Bash
      source:
        type: Inline
        spec:
          script: echo "<+pipeline.variables.my_var>"
```

**Good**

This example correctly uses an input variable and references it within the script, promoting clarity and flexibility.

```yaml
template:
  name: Example Step Template - Good
  type: Step
  spec:
    type: ShellScript
    spec:
      shell: Bash
      source:
        type: Inline
        spec:
          script: echo "${SOME_VAR}"
      environmentVariables:
        - name: SOME_VAR
          type: String
          value: <+input>
```

## Stage Template

Stage templates are a great way to standardize complex workflows and deployment stages across multiple pipelines. They enable consistent application deployment practices, promoting reliability and efficiency. Just like with step templates, you should mark all configurable fields as `<+input>`, creating a clear interface for those using the template. This approach ensures that stage templates remain flexible and adaptable to varying use-cases, ultimately contributing to the robustness and scalability of your DevOps processes.

In terms of configurable parameters, stage templates offer a wide range. You should generally set values such as `environment`, `infrastructure`, `connectors`, `namespace`, and other stage-specific fields as runtime inputs. This practice provides maximum flexibility when integrating these templates into pipelines later.

While marking certain fields within steps as `<+input>` for user configuration might seem intuitive, this can break encapsulation and should be avoided when possible. Instead, aim to create a well-defined interface by utilizing **stage variables** and marking them as `<+input>`. You can then incorporate these into the step by referencing them as `<+stage.variables.X>`. This principle applies whether you're using inline steps or referencing step templates.

To further clarify these points, below are examples illustrating both improper and proper practices:

**Bad**

In this example, a field within a step is directly marked as `<+input>`, which disrupts encapsulation.

```yaml
template:
  name: Stage Template Example - Bad
  identifier: Stage_Template_Example_Bad
  type: Stage
  spec:
    type: CI
    spec:
      cloneCodebase: true
      execution:
        steps:
          - step:
              type: Run
              name: echo
              identifier: echo
              spec:
                shell: Bash
                command: echo "${MY_VAR}"
                envVariables:
                  MY_VAR: <+input>
```

**Good**

This example effectively utilizes a stage variable marked as <+input>, maintaining encapsulation and providing a clear interface.

```yaml
template:
  name: Stage Template Example - Good
  identifier: Stage_Template_Example_Good
  type: Stage
  spec:
    type: CI
    spec:
      cloneCodebase: true
      execution:
        steps:
          - step:
              type: Run
              name: echo
              identifier: Run_1
              spec:
                shell: Bash
                command: echo "${MY_VAR}"
                envVariables:
                  MY_VAR: <+stage.variables.my_var>
    variables:
      - name: my_var
        type: String
        description: ""
        value: <+input>
```

## Pipeline Templates

Pipeline templates are a fantastic tool for standardizing the entire CI/CD process across a diverse set of projects or teams. They provide a comprehensive framework for defining end-to-end workflows, including various stages, steps, environment variables, and other configurations.

When a step in a pipeline requires user input, it's advisable to first create a corresponding stage-level variable, reference this in the step using `<+stage.variables.X>`, and then create a corresponding pipeline-level variable and reference it by setting the value of the stage variable to `<+pipeline.variables.X>`.

So why not just reference the pipeline variable directly in the step in this case? This may seem like an unnecessary level of indirection at first, but later on if you decide to make a template out of the stage, this will make it much easier without having to update all the references to `<+pipeline.variables.X>`.


## Secrets

When defining a variable in a template as a `secret`, there are additional considerations to bear in mind.

For instance, it's not currently supported to have multiple levels of indirection with secrets. Let's consider an example: You're creating a pipeline containing a stage-level template, following the guidelines mentioned above. This stage template has a variable aws_secret_key marked as a secret and `<+input>`. While using this in your pipeline, you might create a pipeline-level variable named aws_secret_key also marked as a secret and `<+input>`, and set the stage-level value to `<+pipeline.variables.aws_secret_key>`. However, this creates a problem. Now you have a pipeline-level variable marked as a secret, being passed into the stage-level variable which is also expecting a secret. This can lead to resolution issues.

To circumvent this problem, define all variables in stage and step-level templates as non-secret types. Then, depend on the consumers of these templates to create higher-level variables marked as secret. This approach ensures the secure handling of sensitive data without the complications of multilevel indirection.


## Reference vs. Copy

When using a template, you have the options to either **Use Template** or **Copy Template**.

Choosing the **Use Template** option means that you are creating a *reference* to the template. In this case, any updates made to the template will automatically reflect for all who are using it. For instance, if you have created a stage template for CI and later decide to add an image scanning step, this can be incorporated directly into the template. Consequently, everyone referencing this template will have the new step included in their configuration automatically. For more details about how updates are managed, refer to the [versioning](#versioning) section.

On the other hand, the **Copy Template** option can be useful when you wish to provide a starting point but want to allow complete flexibility over the configuration. This approach can be beneficial in certain situations but should be used with caution, as it can lead to configuration sprawl.

As a general rule, start with the **Use Template** option and only opt for **Copy Template** when absolutely necessary. This ensures that updates to the template benefit all users and helps prevent unnecessary divergence in configuration.


## Failure strategies and other advanced configurations

When possible, it's best to mark all the fields as `<+input>` to ensure the greatest amount of flexibility by the consumer.


## Versioning

Proper versioning of templates is an important part of maintaining a stable and efficient CI/CD process. It facilitates the gradual rollout of template changes, thus enabling users to test and adapt to new versions in non-critical environments before fully deploying them in production. This strategy effectively mitigates risks associated with introducing new template versions.

### Pinning to Stable Version

When utilizing a pipeline as a reference, you're given the choice to either select a specific version or opt for `Always use the stable version`. By selecting the latter, your pipeline is always kept up-to-date. Whenever a new version is released and marked as `stable`, your pipeline will automatically adopt any updates made in this revised template. This feature streamlines the integration of improvements and new features, eliminating the need for manual intervention to update the templates. Nonetheless, it's important to thoroughly test each new version in a non-production environment to ensure stability and compatibility with your pipeline's configuration.


### Testing Changes

Before implementing any modifications, it's prudent to create a new version of your template. This practice safeguards your existing version from inadvertent overwrites.

After saving your modifications to the new version, you can then create a pipeline that utilizes your template to test out the new functionality. Once you're satisfied with the changes, consumers of your template can update the version they're referencing to incorporate the changes. You also have the option to `Set as Stable` for your new version. As a result, any consumer [using the stable version](#pinning-to-stable-version) will automatically receive the updates.
