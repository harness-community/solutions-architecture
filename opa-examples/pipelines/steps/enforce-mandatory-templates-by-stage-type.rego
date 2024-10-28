# Policy: Enforce Mandatory Templates based on stage.type and template.type with exemption for specified pipelines
package pipeline

import future.keywords.if
import future.keywords.in

#### BEGIN - Policy Controls ####
#
# Inputs:
#	stage_type = Determines the type of stage where the mandatory templates should reside.
#     This filters out the stages that do not match the required type and lowers the chance
#     of a false result
#   resource_type = This should match the type of templates which will be mandatory in the
#     chosen stage_type
#   mandatory_templates = List of mandatory templates that should be included in all stages
#     the chosen stage_type
# 	exempted_pipelines = A list of objects containing the org+project+pipeline identifier
# 	  combinations which are allowed to bypass this rule. Any pipeline that matches an
# 	  entry will bypass this policy evaluation altogether
#     Each entry must be separted by a comma and include the following keys:
#       `org`: Indentifier for the specified pipeline's containing organization in Harness
#       `project`: Indentifier for the specified pipeline's containing project in Harness
#       `pipeline`: Indentifier for the specified pipeline
# 	error_message = Displays the error message using sprintf and is used to control what information the policy returns when a violation occurs

stage_type            = "CI"
resource_type         = "stepGroup"
mandatory_templates   = ["account.requiredScanners"]

exempted_pipelines = [
	{"org": "default", "project": "demo", "pipeline": "demo_pipeline"}
]

error_message(stage) := sprintf("Failed: The stage '%s' with identifier('%s') does not include one or more mandatory step_group templates: [%s]", [stage.name, stage.identifier, concat(",", mandatory_templates)])

#### END   - Policy Controls ####

#### BEGIN - Pipeline Step Type Validation ####
# Return the base pipeline details
pipeline_details = return_pipeline_object(input.pipeline)

# Boolean evaluation to determine if the pipeline includes the stage.type to evaluate
has_required_stages {
	input.pipeline.stages[_].stage.type == stage_type
} else if {
	input.pipeline.stages[_].parallel[_].stage.type == stage_type
} else := false

# Return the IDs of the stage that match the stage.type
current_required_stages(obj) := output {
	all_stages = [return_stage_object(elem) | some elem in walk_document(obj, "stage")]
	output := [elem | some id, elem in all_stages; elem.stage.type == stage_type]
}

# Boolean evaluation to determine if the pipeline is exempt from this policy
is_pipeline_exempt {
	pipeline      = input.pipeline
	exempted_orgs = [elem | some elem in exempted_pipelines; elem.org == pipeline.orgIdentifier]
	exempted_prjs = [elem | some elem in exempted_orgs; elem.project == pipeline.projectIdentifier]
    exempted_pipe = [elem.pipeline | some elem in exempted_prjs]
    array_contains(exempted_pipe, pipeline.identifier)
}

# Deny pipelines that use forbidden items in steps not included in approved templates
deny[msg] {
	# If this is an exempt pipeline (Org+project+pipeline) then skip processing the rule
    not is_pipeline_exempt
	# Only process this policy if the pipeline includes required stages
    has_required_stages

	# Walk the entire document to retrieve all paths to the specified resource_type
	resources := [elem | some elem in walk_document(input, resource_type)]

	# Generate a list of objects containing all the resource details for each found path
	evaluated_steps = [
    	object.union(
        	return_step_object(resource),
            object.union(
            	return_stage_object(resource),
	            pipeline_details
            )
        ) | some resource in resources
    ]

    # Collect details on all of the evalution stages to allow us to further filter our results

	# For every evalution stage, we need to evaluate for the existence of the mandatory_templates
    some stage in current_required_stages(input)[_]

	# Return a list of resources within the stage classification
    step_objects = [elem | some elem in evaluated_steps; elem.stage.identifier == stage.identifier]

    # Finally, process a failure if the required template does not exist in the current stage. If found,
    # the length of the list will be greater than zero
    count([elem | some elem in step_objects; verify_step_templates(elem)]) != count(mandatory_templates)

    # Display the error message.
	msg = error_message(stage)
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
	count([resource | some resource in templates; array_contains(mandatory_templates, resource)]) > 0
}

#### END   - Pipeline Step Type Validation ####

#### BEGIN - Pipeline Data Normalization ####

# Return a formatted and normalized object of Pipeline details
return_pipeline_object(elem) := output if {
	output := {"pipeline": {
		"identifier": elem.identifier,
		"name": elem.name,
		"templateRef": return_template_details(elem),
		"projectIdentifier": elem.projectIdentifier,
		"orgIdentifier": elem.orgIdentifier,
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
		"type": stage.type,
		"templateRef": return_template_details(stage),
	}}
} else := output if {
    stage := return_resources_with_template(elem)
    output := {"stage": {
		"identifier": stage.identifier,
		"name": stage.name,
		"type": stage.type,
		"templateRef": return_template_details(stage),
	}}
}

# Return a formatted and normalized object of Step details
return_step_object(elem) := output if {
	step := return_resources_with_template(elem)
	output := object.union(step, object.union(
        {
		    "templateRef": return_template_details(step),
            "document_path": format_notated_array(elem)
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
