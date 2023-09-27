# OPA Policy: 002 - Enforcing a Stage Policy - Step 4
package pipeline

import future.keywords.in

###############################################################################
# Important Note: Each line of a rule is evaluated until the condition returns
# False or the rule reaches the final line of the section.
###############################################################################

###############################################################################
# Example #4:
# This example will only verify the Approval stage exists if there is a Continuous
# Delivery (CD) stage included -AND- that the stage comes -BEFORE- the CD stage.
#
# Verbosely handles the checks and returns accurate results
#	- What if only certain environments require approval stages?
#
#
###############################################################################

# Include a special set of keywords to allow for list comprehension
# -- Note --
# if using the following as a standalone policy, then please uncomment out the
# following import statement(s)
# import future.keywords.in

deny["Every pipeline with a CD stage must include an Approval stage immediately BEFORE the CD Stage"] {
	# Verify that there are Deployment stages
	has_deployment_stages

	# ... check to see that at least one Approval stage exists
	has_approval_stages

	# ... evaluate each stage in the current deployment_stages list
	some stage in current_deployment_stages

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
###############################################################################
