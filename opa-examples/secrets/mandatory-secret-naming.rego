package secret

#### BEGIN - Name Validation ####

# Must have a good name - 'secret' is not valid
deny[msg] {
	secret := input.secret
	secret.name == "secret"

	msg := sprintf("Secret '%s' does not include a valid name.  Must be descriptive and cannot be 'secret'", [secret.name])
}

#### END   - Name Validation ####
