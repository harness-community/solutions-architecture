# OPA Policy: Restrict Pipeline value based on list except in approved templates
# recursive-restrict-step-value-except-valid-template.rego
package pipeline

import future.keywords.if
import future.keywords.in

#### BEGIN - Policy Controls ####
#
# Inputs:
#   approved_templates = List of template references (with hierarchy e.g. account.templateRef) which will bypass this rule
#   allow_any_account_template  = True/False - Will allow any Account-Level template to bypass this rule (if set, ignores the list)
#   allowed_pipelines  = A list of objects containing the org+project+pipeline identifier
#     combinations which are allowed to bypass this rule. Any pipeline that matches an
#     entry will bypass this policy evaluation altogether
#   Each entry must be separted by a comma and include the following keys:
#     `org`: Indentifier for the specified pipeline's containing organization in Harness
#     `project`: Indentifier for the specified pipeline's containing project in Harness
#     `pipeline`: Indentifier for the specified pipeline
#   forbidden_values   = Used as the base string to trigger the policy deeper check.
#   ignore_keys      = List of key names to ignore when evaluating the document - e.g. ["tokenRef", "secretRef"]
#   error_message = Displays the error message using sprintf and is used to control what information the policy returns when a violation occurs

approved_templates = []
# If allowing project or org level templates, then those must be defined individually
# and this value should be false
allow_any_account_template = true

forbidden_values = []
ignore_keys = []

allowed_pipelines = [
#   {"org":"org_id", "project": "project_id", "pipeline": "pipeline_id"}
]

error_message(evaluated_step, forbidden_value) := sprintf("Failed: The stage '%s' has step '%s' referencing a forbidden secret '%s' and is only valid when used with an approved template %s.", [evaluated_step.stage.name, evaluated_step.name, forbidden_value, approved_templates])

#### END   - Policy Controls ####

#### BEGIN - Pipeline Validation ####

# Boolean evaluation to determine if the pipeline is exempt from this policy
is_pipeline_enforced {
  pipeline     = input.pipeline
  allowed_orgs = [elem | some elem in allowed_pipelines; elem.org == pipeline.orgIdentifier]
  allowed_prjs = [elem | some elem in allowed_orgs; elem.project == pipeline.projectIdentifier]
  allowed_pipe = [elem.pipeline | some elem in allowed_prjs]
  array_contains(allowed_pipe, pipeline.identifier)
}

# Deny pipelines with steps that include secret evaluation that match criteria
deny[msg] {
  # Only enforce this policy against restricted pipelines
  not is_pipeline_enforced

  # Return all Step Resources
  some evaluated_step in all_resources("step")

  # Validate this step not included in a valid template
  not is_approved_template(evaluated_step)

  # Return the object with value and ignore empty
  some forbidden_item in forbidden_values
  filtered_data := return_found_with_value(evaluated_step, forbidden_item, false)
  filtered_data != {}

  # Verify that the returned value is not a key that should be ignored
  not array_contains(ignore_keys, filtered_data.key)

  # Then raise a message
  msg = error_message(evaluated_step, filtered_data.value)
}

# Verify the templates based on the hierachy of the pipeline
verify_step_templates(resource) if {
  templates = [elem |
    some elem in array.concat(
      [
        resource.templateRef,
        resource.stage.templateRef,
        resource.pipeline.templateRef,
      ],
      [elem.templateRef | some elem in resource.stepGroups],
    )
    elem != "missing"
  ]
  count([resource | some resource in templates; array_contains(approved_templates, resource)]) > 0
}

#### END   - Pipeline Validation ####

#### BEGIN - Pipeline Data Normalization ####
# Return all evaluated resources of provided type - e.g. step or stage
all_resources(type) := output {
  output := [object.union(
    return_step_object(resource),
    object.union(
      return_stage_object(resource),
      return_pipeline_object(input.pipeline),
    ),
  ) | some resource in walk_document(input, type)]
}

# Return a formatted and normalized object of Pipeline details
return_pipeline_object(elem) := output if {
  output := {"pipeline": {
    "identifier": elem.identifier,
    "name": elem.name,
    "templateRef": return_template_details(elem),
  }}
}

# Return a formatted and normalized object of Stage details
# Each layer is read from the top of the `input` resource and therefore, the stage details should be in the
# stage key based on the 3rd elem in the elem variable (which should be path segments from the `walk_document`
# function)
return_stage_object(elem) := output if {
  stage := return_resources_with_template(["pipeline", "stages", elem[2], "stage"])
  output := {"stage": {
    "identifier": stage.identifier,
    "name": stage.name,
    "templateRef": return_template_details(stage),
    "index": elem[2],
  }}
}

# Return a formatted and normalized object of Step details
return_step_object(elem) := output if {
  step := return_resources_with_template(elem)
  output := object.union(step, object.union(
    {
      "templateRef": return_template_details(step),
      "document_path": format_notated_array(elem),
      "stage": return_stage_object(elem).stage,
    },
    {"stepGroups": [{
      "name": elem.name,
      "identifier": elem.identifier,
      "templateRef": return_template_details(elem),
    } |
      some elem in step.stepGroups
      return_template_details(elem) != "missing"
    ]},
  ))
}

#### END   - Pipeline Data Normalization ####

#### BEGIN - Pipeline Evaluation Methods ####

return_template_details(eval_item) := eval_item.template.templateRef if has_key(eval_item, "template")

else := "missing"

# This method will return the formatted resource to include the ancestorial template reference into the
# object only if the step isn't a template.  Otherwise, just return the object details for the resource
return_resources_with_template(resource) := output if {
  formatted_resource = object.union(return_object_by_notation(resource), {"stepGroups": return_resources_with_stepGroup(resource)})
  not has_key(formatted_resource, "template")
  templates = walk_document(input, "template")
  resource_template := [return_object_by_notation(template) | some template in templates; startswith(format_notated_array(resource), format_notated_array(template))]
  count(resource_template) > 0

  output = object.union(formatted_resource, {"template": resource_template[0]})
} else := object.union(return_object_by_notation(resource), {"stepGroups": return_resources_with_stepGroup(resource)})

return_resources_with_stepGroup(resource) := resource_stepGroup if {
  formatted_resource = return_object_by_notation(resource)
  not has_key(formatted_resource, "stepGroup")
  stepGroups = walk_document(input, "stepGroup")
  resource_stepGroup := [return_object_by_notation(stepGroup) | some stepGroup in stepGroups; startswith(format_notated_array(resource), format_notated_array(stepGroup))]
  count(resource_stepGroup) > 0
} else := []

return_found_with_value(evaluated_step, filter_value, exact_match) := output if {
  exact_match == false
  [path, value] := walk(evaluated_step)
#   contains(value, filter_value)
  regex.match(filter_value, value)
  output = {"match": exact_match, "value": value, "key": path[count(path) - 1], "filter": filter_value, "path": format_notated_array(path)}
} else := output if {
  [path, value] := walk(evaluated_step)
  value == filter_value
  output = {"match": exact_match, "value": value, "key": path[count(path) - 1], "filter": filter_value, "path": format_notated_array(path)}
} else := {}

is_approved_template(step) if {
  allow_any_account_template == false
  array_contains(approved_templates, step.templateRef)
} else if {
  contains(step.templateRef, "account.")
}

#### END   - Pipeline Evaluation Methods ####

#### BEGIN - Policy Helper Functions ####

# This method will recursively walk the entire document by parsing out each key and compares it against the
# key type requested.  Upon a pattern match, an array of each path segment is sent back
walk_document(eval_doc, eval_type) = {final_path |
  [path, value] := walk(eval_doc)
  obj_type := path[count(path) - 1]
  obj_type == eval_type

  value != "REGO requires we use any declared variable so this is a workaround"

  final_path := [elem | some elem in path]
}

# Collapse a path segment array into an easy to manage dot notation string
format_notated_array(path) := output if {
  output := concat(".", [format_notation(elem) | some elem in array.slice(path, 0, count(path) - 1)])
}

# Rego does not like to combine integers into a string when concatenating.  This will ensure that the
# number is formatted as a string using a base10 eval
format_notation(eval_elem) := format_int(eval_elem, 10) if is_number(eval_elem)

else := eval_elem

# Query the source document from `input` to search for the value at the provided path.
# Note: The path variable must be an array of path segments
return_object_by_notation(path) := object.get(input, path, {})

array_contains(arr, elem) if {
  arr[_] = elem
}

has_key(x, k) if {
  _ = x[k]
}

return_nonempty_objects(item) {
  item != ""
  item != []
  item != {}
}

#### END   - Policy Helper Functions ####
