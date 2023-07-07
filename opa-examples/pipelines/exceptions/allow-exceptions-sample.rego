# Policy: Allow Exceptions for a Policy
package pipeline

import future.keywords.if
import future.keywords.in

#### BEGIN - Policy Controls ####
#
# Inputs:
#   approved_users     = List of users allowed to bypass this rule
#   approved_groups    = List of user groups allowed to bypass this rule
#   approved_tags      = Object of key/value pairs which must be provided to successfully override this policy

# Exception Handlers
approved_users = []

approved_groups = []

approved_pipeline_tags = {"exception": "approved"}


#### END   - Policy Controls ####

#### BEGIN - Pipeline Step Type Validation ####
# Deny pipelines that use forbidden items in steps not included in approved templates
deny[msg] {
	not verify_exception_handlers

	msg := sprintf("Failed: This pipeline '%s' failed due to some condition.", [input.pipeline.name])
}

# Rule Execption checks
verify_exception_handlers if {
	tmp_output := array.concat(
		[return_count_if_elem_in_list(input.metadata.user.email, approved_users)],
		array.concat(
			[return_count_if_elem_in_list(input.metadata.userGroups, approved_groups)],
			[return_count_if_elem_in_list(input.pipeline.tags, approved_pipeline_tags)],
		)
	)
	count([elem | some elem in tmp_output; elem > 0]) > 0
}

#### END   - Pipeline Step Type Validation ####

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
	output := count([item | some item in items; array_contains(eval_arr, return_notated_obj(item))])
} else := output if {
	is_object(items)
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

#### END   - Policy Helper Functions ####
