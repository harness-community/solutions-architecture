package secret

import future.keywords.in

#### BEGIN - Policy Controls ####
allowed_secret_managers := [
	"harnessSecretManager"
]

#### END   - Policy Controls ####

#### BEGIN - Secret Manager Validation ####

# Must include a secret manager identifier
deny[msg] {
	secret := input.secret
	not secret.spec.secretManagerIdentifier

	msg := sprintf("Secret '%s' does not include a Secret Manager", [secret.name])
}

# Must be configured to use an approved secret manager
deny[msg] {
	secret := input.secret
	not array_contains(allowed_secret_managers, secret.spec.secretManagerIdentifier)

	msg := sprintf("Secret '%s' is not configured to use an approved Secret Manager ('%s').  Approved secret Managers must be one of the following - [%s]", [secret.name, secret.spec.secretManagerIdentifier, concat(", ", allowed_secret_managers) ])
}

#### END   - Secret Manager Validation ####

# Helper Functions
array_contains(arr, elem) {
	arr[_] = elem
}
