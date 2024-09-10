# OPA Policy: Restrict Pipeline Execution except by specific users or groups
package pipeline

import future.keywords.if
import future.keywords.in

#### BEGIN - Policy Controls ####
#
# Inputs:
#   approved_users     = List of users allowed to bypass this rule
#   approved_groups    = List of user groups allowed to bypass this rule
#   allow_webhooks     = True/False to enable bypassing of this policy when the pipeline run via a Trigger/Webhook
# 	exempted_pipelines = A list of objects containing the org+project+pipeline identifier
# 	  combinations which are allowed to bypass this rule. Any pipeline that matches an
# 	  entry will bypass this policy evaluation altogether
#     Each entry must be separted by a comma and include the following keys:
#       `org`: Indentifier for the specified pipeline's containing organization in Harness
#       `project`: Indentifier for the specified pipeline's containing project in Harness
#       `pipeline`: Indentifier for the specified pipeline
# 	error_message = Displays the error message using sprintf and is used to control what information the policy returns when a violation occurs

approved_users = []

approved_groups = []

allow_webhooks = true

enforced_pipelines = [
	{"org":"default", "project": "demo", "pipeline": "limited_access_pipeline"}
]

#### END   - Policy Controls ####

#### BEGIN - Pipeline Validation ####

# Boolean evaluation to determine if the pipeline is exempt from this policy
is_pipeline_enforced {
	pipeline      = input.pipeline
	enforced_orgs = [elem | some elem in enforced_pipelines; elem.org == pipeline.orgIdentifier]
	enforced_prjs = [elem | some elem in enforced_orgs; elem.project == pipeline.projectIdentifier]
    enforced_pipe = [elem.pipeline | some elem in enforced_prjs]
    array_contains(enforced_pipe, pipeline.identifier)
}

# Deny pipelines execution for specific pipelines
deny[msg] {
	# Only enforce this policy against restricted pipelines
	is_pipeline_enforced

	# Exit this policy as successful if the pipeline started via a Trigger
	is_webhook

	# Allow exception handlers.  Comment out if no exceptions should be supported.
	not verify_exception_handlers

	msg := sprintf("Failed: This pipeline '%s' can only be executed by approved users.", [input.pipeline.name])
}

# Rule Execption checks
verify_exception_handlers if {
	tmp_output := array.concat(
		[return_count_if_elem_in_list(input.metadata.user.email, approved_users)],
		[return_count_if_elem_in_list(input.metadata.userGroups, approved_groups)]
	)
	count([elem | some elem in tmp_output; elem > 0]) > 0
}

# Pipelines triggered via webhook contain no metadata.user value
is_webhook if {
	allow_webhooks
	input.metadata.user != "null"
} else := false

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
