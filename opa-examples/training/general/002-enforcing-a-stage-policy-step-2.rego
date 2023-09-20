# OPA Policy: 002 - Enforcing a Stage Policy - Step 2
package pipeline

###############################################################################
# Important Note: Each line of a rule is evaluated until the condition returns
# False or the rule reaches the final line of the section.
###############################################################################

###############################################################################
# Example #2:
# This example will only verify the Approval stage exists if there is a Continuous
# Delivery (CD) stage included
#
# The issue with this policy is that it only looks to verify if there is a CD
# stage.
#	- What if approval is only required when going to prod?
#	- What if the approval is -AFTER- the deployment
#
###############################################################################
deny["Every pipeline with a CD stage must include an Approval stage"] {
	# Verify that there are Deployment stages
	deployment_stages

	# ... check to see that at least one Approval stage exists
	not approval_stages
}

deployment_stages {
	input.pipeline.stages[i].stage.type == "Deployment"
}
approval_stages {
	input.pipeline.stages[i].stage.type == "Approval"
}
###############################################################################
