# Policy: Restrict Pipeline Codebase Connectors
package pipeline

import future.keywords.if
import future.keywords.in

#### BEGIN - Policy Controls ####
# Inputs:
#   approved_templates = List of templates that should allow the use of the forbidden_items
# 	filter_object = Object to filter for forbidden items. Must be a string in dot-notation format relative to a 'pipeline'
#     example:
#       `properties.ci.codebase.connector` is relative to the `pipeline` object…. such as `input.pipline.properties.ci.codebase.connector`
#       `delegateSelectors` is relative to the `pipeline` object…. such as `input.pipline.delegateSelectors`
# 	forbidden_items = List of values which should be forbidden in any configuration item of a pipeline (example: CodeBase Connectors, delegateSelectors, etc)
# 	error_message = Displays the error message using sprintf and is used to control what information the policy returns when a violation occurs
#
# Returned Step Object
#   evaluated_step = This a single JSON object containing the complete step object including keys called `pipeline` and `stage` which
#					include the name, identifier, and templateRef (if empty, then the value is 'missing').  In addition, each parental
#					stepGroup is included as a list of name, identifier, and templateRef (if empty, then the value is 'missing').
# 	eval_object    = The returned filter_object value for the currently evaluated step

# Approved Templates
approved_templates  = ["Valid_CI"]

filter_object 	    = "properties.ci.codebase.connector"
forbidden_items     = ["account.default_github_access"]
error_message(pipeline, eval_obj) :=sprintf("Failed: The pipeline '%s' has a CI Codebase Connector '%s' that is forbidden and only valid when used with an approved template %s. ", [pipeline.name, eval_obj, approved_templates])

#### END   - Policy Controls ####

#### BEGIN - Pipeline Step Type Validation ####

    # Restrict Forbidden Connectors from being used as Codebase connectors
    deny[msg] {
        pipeline := return_pipeline_object(input.pipeline)

	    eval_object = return_notated_obj(object.get(pipeline, split(filter_object, "."), {}))

        not array_contains(approved_templates, pipeline.templateRef)
        array_contains(forbidden_items, convert_to_array(eval_object)[_])

	    msg = error_message(pipeline, eval_object)
    }

#### END   - Pipeline Step Type Validation ####

#### BEGIN - Pipeline Data Normalization ####

# Return a formatted and normalized object of Pipeline details
return_pipeline_object(elem) := output if {
	output := object.remove(object.union(elem, {
		"templateRef": return_template_details(elem),
        "has_CI_stages": check_if_has_stage_type("CI"),
        "has_CD_stages": check_if_has_stage_type("Deployment"),
	}), ["stages"])
}

#### END   - Pipeline Data Normalization ####

#### BEGIN - Pipeline Evaluation Methods ####

return_template_details(eval_item) := eval_item.template.templateRef if has_key(eval_item, "template")

else := "missing"

return_notated_obj(eval_item) := eval_item.identifier if {
	eval_item.projectIdentifier != ""
} else := concat(".", ["org", eval_item.identifier]) if {
	eval_item.orgIdentifier != ""
} else := concat(".", ["account", eval_item.identifier]) if {
	eval_item.identifier != ""
} else := eval_item

check_if_has_stage_type(stage_type) := output if {
    output := count([elem.identifier | some elem in input.pipeline.stages[_]; elem.type == stage_type]) > 0
} else := false

#### END   - Pipeline Evaluation Methods ####

#### BEGIN - Policy Helper Functions ####

    array_contains(arr, elem) if {
        arr[_] = elem
    }

    has_key(x, k) if {
        _ = x[k]
    }

    convert_to_array(eval) := [eval] if {
    	is_string(eval)
    } else := eval

#### END   - Policy Helper Functions ####
