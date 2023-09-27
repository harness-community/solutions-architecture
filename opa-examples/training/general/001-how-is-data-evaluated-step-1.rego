# OPA Policy: 001 - How is data evaluated - Step 1
package pipeline

###############################################################################
# Important Note: Each line of a rule is evaluated until the condition returns
# False or the rule reaches the final line of the section.
###############################################################################

###############################################################################
# Example #1:
# This example looks for each stage and then returns a formatted message
###############################################################################
allow [msg] {
	# Gather all the stages in the document
	stage = input.pipeline.stages[_].stage

	# Foreach match of stage.type, return a message with matching stage identifier.
	msg = sprintf("This pipeline has a stage called: %s", [stage.identifier])
}
###############################################################################

