# Policy: Recursively Restrict Step Types except in valid Template
package pipeline

import future.keywords.if
import future.keywords.in

#### BEGIN - Policy Controls ####
#
# Inputs:
#   approved_templates = List of templates that should allow the use of the forbidden_items
# 	filter_object = Object to filter for forbidden items. Must be a string in dot-notation format relative to a 'step'
#     example:
#       `spec.connector` is relative to the `step` object…. such as `input.pipline.stages.0.stage.steps.0.step.spec.connector`
#       `type` is relative to the `step` object…. such as `input.pipline.stages.0.stage.steps.0.step.type`
# 	forbidden_items = List of values which should be forbidden in any step of a pipeline (example: StepTypes, ConnectorRefs, etc)
# 	error_message = Displays the error message using sprintf and is used to control what information the policy returns when a violation occurs
#
# Returned Step Object
#   evaluated_step = This a single JSON object containing the complete step object including keys called `pipeline` and `stage` which
#					include the name, identifier, and templateRef (if empty, then the value is 'missing').  In addition, each parental
#					stepGroup is included as a list of name, identifier, and templateRef (if empty, then the value is 'missing').
# 	eval_object    = The returned filter_object value for the currently evaluated step

# Approved Templates
approved_templates 	= ["Valid_CI", "CI_Verification", "account.Blackduck_Scanning"]

filter_object 		= "type"
forbidden_items 	= ["Run", "ShellScript"]
error_message(step, step_object) := sprintf("Failed: The stage '%s' has step '%s' that is forbidden type '%s' and only valid when used with an approved template %s.  Currently using a template of %s", [step.stage.name, step.name, step.type, approved_templates, step_object])

#### END   - Policy Controls ####

#### BEGIN - Pipeline Step Type Validation ####

# Deny pipelines that use forbidden items in steps not included in approved templates
deny[msg] {
	pipeline_details = return_pipeline_object(input.pipeline)
	resource := [elem | some elem in walk_document(input, "step")][_]

	evaluated_step = object.union(return_step_object(resource), object.union(return_stage_object(resource), pipeline_details))

	eval_object = return_notated_obj(object.get(evaluated_step, split(filter_object, "."), {}))

	# Validate the templates for the Step, StepGroup, Stage, and Pipeline to determine if the value matches approved templates
	not verify_step_templates(evaluated_step)

	# If no approved template, then we need to evaluate the connectorRef for the step to determine if there is
	# a forbidden connector in use
	array_contains(forbidden_items, eval_object)

	msg = error_message(evaluated_step, eval_object)
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

#### END   - Pipeline Step Type Validation ####

#### BEGIN - Pipeline Data Normalization ####

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
	}}
}

# Return a formatted and normalized object of Step details
return_step_object(elem) := output if {
	step := return_resources_with_template(elem)
	output := object.union(step, object.union(
        {
		    "templateRef": return_template_details(step)
        },{
		"stepGroups": [{
			"name": elem.name,
			"identifier": elem.identifier,
			"templateRef": return_template_details(elem),
		} |
			some elem in step.stepGroups
			return_template_details(elem) != "missing"
		],
	}))
}

#### END   - Pipeline Data Normalization ####

#### BEGIN - Pipeline Evaluation Methods ####

return_template_details(eval_item) := eval_item.template.templateRef if has_key(eval_item, "template")

else := "missing"

return_notated_obj(eval_item) := eval_item.identifier if {
	eval_item.projectIdentifier != ""
} else := concat(".", ["org", eval_item.identifier]) if {
	eval_item.orgIdentifier != ""
} else := concat(".", ["account", eval_item.identifier]) if {
	eval_item.identifier != ""
} else := eval_item

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

#### END   - Policy Helper Functions ####
