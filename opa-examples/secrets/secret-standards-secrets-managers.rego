# Policy: Secrets Standards - Secrets Storage Managers
package secret

import future.keywords.in
import future.keywords.if

#### BEGIN - Policy Inputs ####
#
# Inputs:
#   approved_secret_managers = List of approved secrets managers


approved_secret_managers := [
	"harnessSecretManager"
]
#### END   - Policy Inputs ####

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
	not array_contains(approved_secret_managers, secret.spec.secretManagerIdentifier)

	msg := sprintf("Secret '%s' is not configured to use an approved Secret Manager ('%s').  Approved secret Managers must be one of the following - [%s]", [secret.name, secret.spec.secretManagerIdentifier, concat(", ", approved_secret_managers) ])
}

#### END   - Secret Manager Validation ####


#### BEGIN - Policy Helper Functions ####

array_contains(arr, elem) if {
	arr[_] = elem
}

#### END   - Policy Helper Functions ####
