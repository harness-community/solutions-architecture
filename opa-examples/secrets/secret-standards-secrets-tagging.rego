# Policy: Secrets Standards - Restricted Secret Management
package secret

import future.keywords.in
import future.keywords.if

#### BEGIN - Policy Inputs ####
#
# Inputs:
#   approved_users	     = List of users allowed to bypass this rule
#   approved_groups	     = List of user groups allowed to bypass this rule
#   - NOTE: (Account Groups start with `account.` and Org Groups start with `org.`)
#   approved_tags		 = Object of key/value pairs which must be provided to successfully override this policy
#   restricted_secret_id = String value of the secret to which restrict access
#   - NOTE: (Account Secret start with `account.` and Org Secret start with `org.`)

approved_users = []
approved_groups = []
approved_secret_tags = {}
restricted_secret_identifiers = []

#### END   - Policy Inputs ####

#### BEGIN - Secret Validation ####
# Deny pipelines that use forbidden items in steps not included in approved templates
deny[msg] {
	# If exception handlers are not met, then we will process the policy
	not verify_exception_handlers

	# Policy Evaluation Steps
	secret := input.secret
	array_contains(restricted_secret_identifiers, return_notated_obj(secret))

	msg := sprintf("Secret '%s' can only be editted by members of the approved users, groups, or with valid tags - %s", [secret.name, approved_groups])
}
#### END   - Secret Validation ####


#### BEGIN - Policy Controls ####

# Rule Execption checks
verify_exception_handlers if {
	tmp_output := array.concat(
		[return_count_if_elem_in_list(input.metadata.user.email, approved_users)],
		array.concat(
			[return_count_if_elem_in_list(input.metadata.userGroups, approved_groups)],
			[return_count_if_elem_in_list(input.secret.tags, approved_secret_tags)]
		)
	)
	count([elem | some elem in tmp_output; elem > 0]) > 0
}

#### END   - Policy Controls ####

#### BEGIN - Policy Evaluation Methods ####

return_notated_obj(eval_item) := eval_item.identifier if {
	eval_item.projectIdentifier != ""
} else := concat(".", ["org", eval_item.identifier]) if {
	eval_item.orgIdentifier != ""
} else := concat(".", ["account", eval_item.identifier]) if {
	eval_item.identifier != ""
} else := eval_item

return_count_if_elem_in_list(items, eval_arr) := 0 if {
  has_value(eval_arr)
} else := output if {
	is_array(items)
	output := count([item | some item in items; array_contains(eval_arr, return_notated_obj(item))])
} else := output if {
	is_object(items)
	output := to_number(has_all_keys_and_values(items, eval_arr))
} else := count([item | some item in [items]; array_contains(eval_arr, return_notated_obj(item))])

#### END   - Policy Evaluation Methods ####

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

has_value(elem) if {
	is_array(elem)
	count(elem) > 0
} else if {
	is_object(elem)
	count(elem.keys) > 0
} else if {
	elem != ""
} else := false

#### END   - Policy Helper Functions ####
