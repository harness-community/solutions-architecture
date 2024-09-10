# Policy: Enforce API Key Token Age
package pipeline

import future.keywords.if
import future.keywords.in

#### BEGIN - Policy Controls ####
#
# Inputs:
#   maximum_years = How many years can a token be created.
#   maximum_months = How many months can a token be created.
#   maximum_days = How many days can a token be created.

# Control Board
maximum_years = 0
maximum_months = 0
maximum_days = 7

#### END   - Policy Controls ####

#### BEGIN - Policy Validation ####

token_created := return_formatted_epoch(input.token.validFrom)
token_valid_till := time.add_date(return_formatted_epoch(input.token.validTo),0, 0, 0)

# Returns as an array of numbers in the format of
# [years, months, days, hours, minutes, seconds]
time_diff := time.diff(token_created, token_valid_till)

# Deny pipelines that use forbidden items in steps not included in approved templates
deny[msg] {
    restrict_token_age
    msg := sprintf("Invalid Length for Token Creation. Harness Access Tokens may only be created for up to %s days", [format_notation(maximum_days)])
}

restrict_token_age if {
	# Raise an issue if the maximum years for the token exceeds value
    time_diff[0] > maximum_years
} else if {
	# Raise an issue if the maximum months for the token exceeds value
    time_diff[1] > maximum_months
} else if {
	# Raise an issue if the maximum days for the token exceeds value and account
	# for a matching days value by supporting a 24hr option as well
    time_diff[2] >= maximum_days
    time_diff[3] != 0
} else := false

#### END   - Policy Validation ####

#### BEGIN - Policy Helper Functions ####

# Return a nanosecond formatted epoch timestamp
return_formatted_epoch(time_input) := output {
	output := time_input * 1000000
}
# Rego does not like to combine integers into a string when concatenating.  This will ensure that the
# number is formatted as a string using a base10 eval
format_notation(eval_elem) := format_int(eval_elem, 10) if is_number(eval_elem)

#### END   - Policy Helper Functions ####
