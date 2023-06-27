# Policy: Mandate specific Pipeline CI Build Farm Namespaces

package pipeline

import future.keywords.if
import future.keywords.in

#### BEGIN - Policy Controls ####
#
# Inputs:
#   approved_namespaces = List of approved namespaces for use with CI Build actions

approved_namespaces = ["harnessci"]

#### END   - Policy Controls ####

#### BEGIN - Pipeline Step Type Validation ####
deny[msg] {
	stage = input.pipeline.stages[_].stage

	stage.type == "CI"

	stage_namespace := stage.spec.infrastructure.spec.namespace

	not array_contains(approved_namespaces, stage_namespace)

	msg := sprintf("CI Builds are only approved for the specified namespaces '%s'. The namespace '%s' is not approved.", [approved_namespaces, stage_namespace])
}

#### END   - Pipeline Step Type Validation ####

#### BEGIN - Policy Helper Functions ####

array_contains(arr, elem) if {
	arr[_] = elem
}

#### END   - Policy Helper Functions ####
