# OPA Policy: 001 - How is data evaluated - Step 3
package pipeline

###############################################################################
# Important Note: Each line of a rule is evaluated until the condition returns
# False or the rule reaches the final line of the section.
###############################################################################

###############################################################################
# Example #3:
# This example looks for each stage and then filters out any stage that isn't of
# Type == "CI".  In addition, each step is evaluated and returned as part of the
# message
###############################################################################
allow [msg] {
	# Gather all the stages in the document
	stage = input.pipeline.stages[_].stage

	# ... filter out stages to include only a specific type
	stage.type == "CI"

	# Gather all the steps in the currently selected stage
	step = stage.spec.execution.steps[_].step

	# Foreach match of stage.type, return a message with details about every step.
	msg = sprintf("This CI Stage (%s) has a step: %s of type: %s", [stage.identifier, step.identifier, step.type])
}
###############################################################################
