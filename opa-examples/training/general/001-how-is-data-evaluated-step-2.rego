# OPA Policy: 001 - How is data evaluated - Step 2
package pipeline

###############################################################################
# Important Note: Each line of a rule is evaluated until the condition returns
# False or the rule reaches the final line of the section.
###############################################################################

###############################################################################
# Example #2:
# This example looks for each stage and then filters out any stage that isn't of
# Type == "CI".  Only matching conditions will be returned as a message
###############################################################################
allow [msg] {
	# Gather all the stages in the document
	stage = input.pipeline.stages[_].stage

	# ... filter out stages to include only a specific type
	stage.type == "CI"

	# Foreach match of stage.type, return a message with matching stage identifier.
	msg = sprintf("This Stage is a Continuous Integration (CI) stage: %s", [stage.identifier])
}
###############################################################################
