package secret

#### BEGIN - Description Validation ####

# Must have a well-written description
deny[msg] {
	secret := input.secret
	regex.match(secret.description, "secret description")

	msg := sprintf("Secret '%s' does not include a valid description.  Must be descriptive and cannot contain 'secret description'", [secret.name])
}

#### END   - Description Validation ####
