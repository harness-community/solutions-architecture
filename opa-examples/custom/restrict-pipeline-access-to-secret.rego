# OPA Policy: Restrict Pipeline access to secret except in valid pipelines
package pipeline

import future.keywords.if
import future.keywords.in

#### BEGIN - Policy Controls ####
#
# Inputs:
#   exact_match        = True/False - should we use the items in the forbidden_secrets as a regex instead of a full string match
#   approved_groups    = True/False - verify any secret against a direct pattern AND with jexl conditions (<+secrets.getValue("secret")>)
#   fobidden_secrets   = List of secret references which this policy will forbid usage except by allowed_pipelines
# 	allowed_pipelines  = A list of objects containing the org+project+pipeline identifier
# 	  combinations which are allowed to bypass this rule. Any pipeline that matches an
# 	  entry will bypass this policy evaluation altogether
#     Each entry must be separted by a comma and include the following keys:
#       `org`: Indentifier for the specified pipeline's containing organization in Harness
#       `project`: Indentifier for the specified pipeline's containing project in Harness
#       `pipeline`: Indentifier for the specified pipeline
# 	error_message = Displays the error message using sprintf and is used to control what information the policy returns when a violation occurs

exact_match = true
include_secrets_jexl = true
fobidden_secrets = []

allowed_pipelines = [
	{"org":"default", "project": "demo", "pipeline": "limited_access_pipeline"}
]

error_message(path, forbidden_key, forbidden_value) := sprintf("Failed: The path '%s' has a configuration referencing a forbidden value '%s' at '%s' and is only valid when used with an approved pipeline %s.", [path, forbidden_value, forbidden_key, allowed_pipelines])

#### END   - Policy Controls ####

#### BEGIN - Pipeline Validation ####

# Boolean evaluation to determine if the pipeline is exempt from this policy
is_pipeline_enforced {
	pipeline      = input.pipeline
	allowed_orgs = [elem | some elem in allowed_pipelines; elem.org == pipeline.orgIdentifier]
	allowed_prjs = [elem | some elem in allowed_orgs; elem.project == pipeline.projectIdentifier]
    allowed_pipe = [elem.pipeline | some elem in allowed_prjs]
    array_contains(allowed_pipe, pipeline.identifier)
}

# Deny pipelines execution for specific pipelines
deny[msg] {
	# Only enforce this policy against restricted pipelines
	not is_pipeline_enforced

	# Walk the entire pipeline object
	[path, value] = walk(input)
    return_nonempty_objects(path)
    return_nonempty_objects(value)

    some forbidden_value in return_all_forbidden_secrets
    return_found_with_value(value, forbidden_value, exact_match)

    fmt_path = format_notated_array(path)
    forbidden_key := path[count(path) - 1]
    msg = error_message(fmt_path, forbidden_key, forbidden_value)
}

return_all_forbidden_secrets := output if {
	include_secrets_jexl
    output := array.concat(
    	fobidden_secrets,
        [concat("",["<+secrets.getValue(\"",elem,"\")>"]) | some elem in fobidden_secrets]
    )
} else := fobidden_secrets

#### END   - Pipeline Validation ####

#### BEGIN - Pipeline Evaluation Methods ####

return_notated_obj(eval_item) := eval_item.identifier if {
	eval_item.projectIdentifier != ""
} else := concat(".", ["org", eval_item.identifier]) if {
	eval_item.orgIdentifier != ""
} else := concat(".", ["account", eval_item.identifier]) if {
	eval_item.identifier != ""
} else := eval_item

return_count_if_elem_in_list(items, eval_arr) := output if {
	is_array(items)
    return_nonempty_objects(eval_arr)
	output := count([item | some item in items; array_contains(eval_arr, return_notated_obj(item))])
} else := output if {
	is_object(items)
    return_nonempty_objects(eval_arr)
    output := to_number(has_all_keys_and_values(items, eval_arr))
} else := count([item | some item in [items]; array_contains(eval_arr, return_notated_obj(item))])

#### END   - Pipeline Evaluation Methods ####

#### BEGIN - Policy Helper Functions ####
return_found_with_value(value, forbidden_value, exact_match) := output if {
	exact_match == false
    contains(value, forbidden_value)
	output = value
} else := output if {
	value == forbidden_value
	output = value
} else := false

# Collapse a path segment array into an easy to manage dot notation string
format_notated_array(path) := output if {
	output := concat(".", [format_notation(elem) | some elem in array.slice(path, 0, count(path) - 1)])
}

# Rego does not like to combine integers into a string when concatenating.  This will ensure that the
# number is formatted as a string using a base10 eval
format_notation(eval_elem) := format_int(eval_elem, 10) if is_number(eval_elem) else := eval_elem

array_contains(arr, elem) if {
	arr[_] = elem
}

has_key(x, k) if {
	_ = x[k]
}

has_all_keys_and_values(truth, check) := true if {
	count([ key | some key,elem in truth; has_key(check, key); elem == check[key]]) == count(object.keys(check))
} else := false

return_nonempty_objects(item) {
	item != ""
    item != []
    item != {}
}

#### END   - Policy Helper Functions ####
