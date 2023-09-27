# OPA Policy: 002 - Enforcing a Stage Policy - Step 5
package pipeline

import future.keywords.in

###############################################################################
# Important Note: Each line of a rule is evaluated until the condition returns
# False or the rule reaches the final line of the section.
###############################################################################

###############################################################################
# Example #5:
# This example will only verify the Approval stage exists if there is a Continuous
# Delivery (CD) stage included -AND- that the stage comes -BEFORE- the CD stage and
# only for named Environment identifiers
#
# Verbosely handles the checks and returns accurate results
#	- What about those complexe pipeline structures?
#
###############################################################################

#### BEGIN - Policy Controls ####

approval_required_envs = ["QA", "PROD"]

#### END   - Policy Controls ####

deny["Every pipeline with a CD stage must include an Approval stage immediately BEFORE the CD Stage"] {
	# Verify that there are Deployment stages
	has_deployment_stages

	# ... check to see that at least one Approval stage exists
	has_approval_stages

	# ... evaluate each stage in the current deployment_stages list
	some stage in current_deployment_stages

	# ... determine if the Environment Identifier matches the approval_required_envs
	array_contains(approval_required_envs, upper(input.pipeline.stages[stage].stage.spec.environment.environmentRef))

	# ... evaluate the list of current Approval stages to ensure the selected stage preceeds it
	count([elem | some elem in current_approval_stages; elem == stage-1]) == 0
}

has_deployment_stages {
	input.pipeline.stages[i].stage.type == "Deployment"
}
has_approval_stages {
	input.pipeline.stages[i].stage.type == "Approval"
}

current_deployment_stages := output {
	output := [id | some id, elem in input.pipeline.stages; elem.stage.type == "Deployment"]
}
current_approval_stages := output {
	output := [id | some id, elem in input.pipeline.stages; elem.stage.type == "Approval"]
}

array_contains(arr, elem) {
	arr[_] = elem
}
###############################################################################
