# Policy: Recursively Restrict Stage values except in valid Template
package pipeline

import future.keywords.if
import future.keywords.in

#### BEGIN - Policy Controls ####
#
# Inputs:
#   approved_pipelines = List of pipelines that should allow the use of the forbidden_items
# 	forbidden_items    = List of values which should be forbidden as the value or part of a the value in any step of a pipeline
# 	exact_match        = Boolean determination if the items listed in forbidden_items must be an exact match for the string provided
# 	error_message      = Displays the error message using sprintf and is used to control what information the policy returns when a violation occurs
#
# Returned Step Object
#   path               = The path within the pipeline containing the invalid information
# 	forbidden_key      = The returned forbidden_item key for the currently evaluated step
# 	forbidden_value    = The returned forbidden_item value for the currently evaluated step

# Approved Pipelines
approved_pipelines = []

forbidden_items = [
    "testing",
    "<+secrets.getValue(\"testing\")>"
]

exact_match = true

error_message(path, forbidden_key, forbidden_value) := sprintf("Failed: The path '%s' has a configuration referencing a forbidden value '%s' at '%s' and is only valid when used with an approved pipeline %s.", [path, forbidden_value, forbidden_key, approved_pipelines])

#### END   - Policy Controls ####

#### BEGIN - Pipeline Step Type Validation ####

# Restrict Forbidden Connectors from being used
deny[msg] {
  # Only enforce this policy against restricted pipelines
  not array_contains(approved_pipelines, input.pipeline.identifier)
  [path, value] = walk(input)
  return_nonempty_objects(path)
  return_nonempty_objects(value)

  some forbidden_value in forbidden_items
  return_found_with_value(value, forbidden_value, exact_match)

  fmt_path = format_notated_array(path)
  forbidden_key := path[count(path) - 1]
  msg = error_message(fmt_path, forbidden_key, forbidden_value)
}

return_nonempty_objects(item) {
  item != ""
  item != []
  item != {}
}

#### END   - Pipeline Step Type Validation ####


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
#### END   - Policy Helper Functions ####
