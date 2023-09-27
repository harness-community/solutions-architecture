# OPA Policy: Restrict Pipeline Definition Branches
package pipeline
import future.keywords.in

# Provide allowed branches and regex
approved_branches := ["development", "release/*"]

###############################################################################
deny[msg] {
  branch := input.pipeline.gitConfig.branch
  count([elem | some elem in approved_branches; glob.match(elem, [], branch)]) == 0

  msg := sprintf("Pipeline source must come from an approved branch schema. The branch '%s' is not allowed based on the approved branches - %s", [branch, approved_branches])
}

###############################################################################

array_contains(arr, elem) {
	arr[_] = elem
}
