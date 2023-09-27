# OPA Policy: 001 - How is data evaluated - Step 4
package pipeline

###############################################################################
# Important Note: Each line of a rule is evaluated until the condition returns
# False or the rule reaches the final line of the section.
###############################################################################

###############################################################################
# Example #4:
# This example looks for each stage and then filters out any stage that isn't of
# Type == "CI".  In addition, each step is evaluated against a list of types from
# the constant `approved_types`. Only matching conditions will be returned as a
# message
###############################################################################
approved_types = [
	"AquaTrivy",
	"BlackDuck",
	"Checkmarx",
	"Gitleaks",
	"Nikto",
	"Owasp",
	"PrismaCloud",
	"Prowler",
	"Snyk",
	"Zap"
]
allow [msg] {
	# Gather all the stages in the document
	stage = input.pipeline.stages[_].stage

	# ... filter out stages to include only a specific type
	stage.type == "CI"

	# Gather all the steps in the currently selected stage
	step = stage.spec.execution.steps[_].step

	# ... check to see if the step type matches one of the approved types by checkin
	#	 each element in the list of approved_types
	approved_types[_] = step.type

	# Foreach match of stage.type and step.type, return a message.
	msg = sprintf("This CI Stage (%s) has a step: %s of type: %s which is required", [stage.identifier, step.identifier, step.type])
}
###############################################################################
