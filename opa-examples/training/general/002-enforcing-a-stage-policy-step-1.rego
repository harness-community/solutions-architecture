# OPA Policy: 002 - Enforcing a Stage Policy - Step 1
package pipeline

###############################################################################
# Important Note: Each line of a rule is evaluated until the condition returns
# False or the rule reaches the final line of the section.
###############################################################################

###############################################################################
# Example #1:
# This example simply looks for any stage of type Approval
#
# The issue with this policy is that it only looks for a single match for an
# unconditional check.
#	- What if it is a CI stage?
#	- What if approval is only required when going to prod?
###############################################################################
deny["All deployments require an approval stage"] {
	not approval_stages
}

approval_stages {
	input.pipeline.stages[i].stage.type == "Approval"
}
###############################################################################
