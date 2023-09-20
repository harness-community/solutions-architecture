package pipeline

# Include a special set of keywords to allow for list comprehension
import future.keywords.in
# Include a special set of keywords to allow for complex conditionals
import future.keywords.if

###############################################################################
# Important Note: Each line of a rule is evaluated until the condition returns
# False or the rule reaches the final line of the section.
###############################################################################

###############################################################################
# Example #1:
# This example will only verify the Approval stage exists if there is a Continuous
# Delivery (CD) stage included -AND- that the stage comes -BEFORE- the CD stage.
#
# Solidly resolves the concerns and validation required to provide consistent results
#
###############################################################################

# -- Note --
# if using the following as a standalone policy, then please uncomment out the
# following import statement(s)
# Include a special set of keywords to allow for list comprehension
# import future.keywords.in
# Include a special set of keywords to allow for complex conditionals
# import future.keywords.if

#### BEGIN - Policy Controls ####

approval_required_envs = ["QA", "PROD"]

#### END   - Policy Controls ####

#### BEGIN - Pipeline Step Type Validation ####

# Restrict Forbidden Connectors from being used
deny[msg] {
	pipeline_details = return_pipeline_object(input.pipeline)
	# Verify that there are Deployment stages
	has_deployment_stages

	# ... check to see that at least one Approval stage exists
	has_approval_stages

	# ... evaluate each stage to find the next deployment stage
	resource := [elem | some elem in walk_document(input, "stage")][_]

	stage = object.union(return_stage_object(resource), pipeline_details)
	stage.details.type == "Deployment"

    # ... determine if the Environment Identifier matches the approval_required_envs
    array_contains(approval_required_envs, upper(stage.details.spec.environment.environmentRef))

	# ... evaluate the list of current Approval stages to ensure the selected stage preceeds it
	count([elem | some elem in current_approval_stages; elem == to_number(resource[2])-1]) == 0

	msg = sprintf("Pipeline Stage (%s) does not have an approval stage immediately before the stage - %s", [stage.identifier, resource])
}

has_deployment_stages {
	resource := [return_stage_object(elem) | some elem in walk_document(input, "stage")][_]
	resource.details.type == "Deployment"
}
has_approval_stages {
	resource := [return_stage_object(elem) | some elem in walk_document(input, "stage")][_]
	resource.details.type == "Approval"
}

current_approval_stages := output {
	output := [elem[2] | some elem in walk_document(input, "stage"); return_stage_object(elem).details.type == "Approval"]
}

#### END   - Pipeline Step Type Validation ####

#### BEGIN - Pipeline Data Normalization ####

# Return a formatted and normalized object of Pipeline details
return_pipeline_object(elem) := output if {
	output := {"pipeline": {
	"identifier": elem.identifier,
	"name": elem.name,
	"templateRef": return_template_details(elem)
	}}
}

# Return a formatted and normalized object of Step details
return_stage_object(elem) := output if {
	stage := return_resources_with_template(elem)
	output := {
	"identifier": stage.identifier,
	"name": stage.name,
	"templateRef": return_template_details(stage),
	"details": stage
	}
}

#### END   - Pipeline Data Normalization ####

#### BEGIN - Pipeline Evaluation Methods ####

return_template_details(eval_item) := eval_item.template.templateRef if has_key(eval_item, "template") else := "missing"

# This method will return the formatted resource to include the ancestorial template reference into the
# object only if the step isn't a template.  Otherwise, just return the object details for the resource
return_resources_with_template(resource) := output if {
	formatted_resource = return_object_by_notation(resource)
	not has_key(formatted_resource, "template")
	templates = walk_document(input, "template")
	resource_template := [return_object_by_notation(template) | some template in templates; startswith(format_notated_array(resource), format_notated_array(template))]
	count(resource_template) > 0

	output = object.union(formatted_resource, {"template": resource_template[0]})
} else := return_object_by_notation(resource)


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
format_notation(eval_elem) := format_int(eval_elem, 10) if is_number(eval_elem) else := eval_elem

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
###############################################################################
