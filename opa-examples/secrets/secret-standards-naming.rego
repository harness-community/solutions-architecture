# Policy: Secrets Standards - Naming and Descriptions
package secret

import future.keywords.in
import future.keywords.if

#### BEGIN - Policy Inputs ####
#
# Inputs:
#   forbidden_secret_prefix = String containing prefix which should never be used for the creation
#   of a secret within Harness. Denies based on regex `startswith`

forbidden_secret_prefix = "secret"
mandatory_desc_prefix   = "Provides access to "
#### END   - Policy Inputs ####


#### BEGIN - Name and Identifier Validation ####

# Must have a good name - Secrets beginning with value of `forbidden_secret_prefix` are not allowed
deny[msg] {
	secret := input.secret
	startswith(lower(secret.name), lower(forbidden_secret_prefix))

	msg := sprintf("Secret '%s' does not include a valid name.  Must be descriptive and cannot begin with '%s'", [secret.name, forbidden_secret_prefix])
}

# Must have a good identifier - Identifiers beginning with value of `forbidden_secret_prefix` are not allowed
deny[msg] {
	secret := input.secret
    fmt_identifier := lower(replace(replace(secret.identifier, " ", "-"), "-", "_"))
    fmt_prefix     := lower(replace(replace(forbidden_secret_prefix, " ", "-"), "-", "_"))
	startswith(fmt_identifier, fmt_prefix)

	msg := sprintf("Secret '%s' does not include a valid identifier.  Must be descriptive and cannot begin with '%s'", [secret.identifier, forbidden_secret_prefix])
}

# Must include a description
deny[msg] {
	secret := input.secret
	secret.description == ""

	msg := sprintf("Secret '%s' does not include any description.  Must be descriptive and must begin with '%s'", [secret.name, mandatory_desc_prefix])
}

# Must include a well-written description
deny[msg] {
	secret := input.secret
    # Note: In this case, we use the negative check as we want to raise the condition if the pattern doesn't match correctly
	not startswith(lower(secret.description), lower(mandatory_desc_prefix))

	msg := sprintf("Secret '%s' does not include a valid description.  Must be descriptive and must begin with '%s'", [secret.name, mandatory_desc_prefix])
}

#### END   - Name and Identifier Validation ####

