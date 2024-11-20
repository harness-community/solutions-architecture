package secret

import future.keywords.in

#### BEGIN - Policy Controls ####
mandatory_tags := [
	"environment",
	"cloud",
	"cost_center",
]

#### END   - Policy Controls ####

#### BEGIN - Tag Validation ####

# Must include tags
deny[msg] {
	secret := input.secret
	not secret.tags

	msg := sprintf("Secret '%s' does not include mandatory tags.  Must include all of the following tags - %s", [secret.name, mandatory_tags[_]])
}

# Must include mandatory tags
deny[msg] {
	secret := input.secret
	count(return_missing_tags) > 0

	msg := sprintf("Secret '%s' does not include mandatory tags.  Must include the tag - %s", [secret.name, return_missing_tags[_]])
}

# Must include a value for all mandatory tags
deny[msg] {
	secret := input.secret
	count(return_missing_tags) == 0
	count(return_empty_tags) != 0

	msg := sprintf("Secret '%s' includes empty values for mandatory tags.  Must set a value for the tag - %s", [secret.name, return_empty_tags[_]])
}

# Must not have a null value for a mandatory tag
deny[msg] {
	secret := input.secret
	count(return_missing_tags) == 0
	count(return_null_tags) != 0

	msg := sprintf("Secret '%s' includes null values for mandatory tags.  Must set a value for the tag - %s", [secret.name, return_null_tags[_]])
}

return_missing_tags := output {
	output := [tag | some tag in mandatory_tags; not array_contains(object.keys(input.secret.tags), tag)]
}

return_empty_tags := output {
	output := [tag | some tag, value in input.secret.tags; value != null; count(value) == 0]
}

return_null_tags := output {
	output := [tag | some tag, value in input.secret.tags; array_contains([null, "null"], value) ]
}

#### END   - Tag Validation ####

# Helper Functions
array_contains(arr, elem) {
	arr[_] = elem
}
