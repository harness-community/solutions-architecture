# Policy: Recursively Restrict Stage values except in valid Template
package pipeline

import future.keywords.if
import future.keywords.in

#### BEGIN - Policy Controls ####
#
# Inputs:
#   approved_templates = List of templates that should allow the use of the forbidden_items
# 	forbidden_items    = List of values which should be forbidden as the value or part of a the value in any step of a pipeline
# 	exact_match        = Boolean determination if the items listed in forbidden_items must be an exact match for the string provided
# 	error_message      = Displays the error message using sprintf and is used to control what information the policy returns when a violation occurs
#
# Returned Step Object
#   evaluated_step     = This a single JSON object containing the complete step object including keys called `pipeline` and `stage` which
#					     include the name, identifier, and templateRef (if empty, then the value is 'missing').  In addition, each parental
#					     stepGroup is included as a list of name, identifier, and templateRef (if empty, then the value is 'missing').
# 	forbidden_value    = The returned forbidden_item value for the currently evaluated step

# Approved Templates
approved_templates = ["Valid_CI", "CI_Verification", "account.Blackduck_Scanning"]

forbidden_items = ["account.GITHUB_PASSWORD", "testing"]

exact_match = false

error_message(evaluated_step, forbidden_value) := sprintf("Failed: The stage '%s' has a configuration referencing a forbidden secret '%s' and is only valid when used with an approved template %s.", [evaluated_step.name, forbidden_value, approved_templates])

#### END   - Policy Controls ####

#### BEGIN - Pipeline Step Type Validation ####

    # Restrict Forbidden Connectors from being used
    deny[msg] {
        pipeline_details = return_pipeline_object(input.pipeline)
	    resource := [elem | some elem in walk_document(input, "stage")][_]

        stage = object.union(return_stage_object(resource), pipeline_details)

        # Validate the templates for the Step, Stage, and Pipeline to determine if the value matches approved templates
        verify_templates(stage)

        some filtered_value in forbidden_items

        return_found_with_value(stage, filtered_value, exact_match) != {}

        msg = error_message(stage, filtered_value)
    }

    # Verify the templates based on the hierachy of the pipeline
    verify_templates(resource) if {
        not array_contains(approved_templates, resource.templateRef)
        not array_contains(approved_templates, resource.pipeline.templateRef)
    }

#### END   - Pipeline Step Type Validation ####

#### BEGIN - Pipeline Data Normalization ####

    # Return a formatted and normalized object of Pipeline details
    return_pipeline_object(elem) := output if {
        output := {"pipeline": {
            "identifier": elem.identifier,
            "name": elem.name,
            "templateRef": return_template_details(elem)
        }}
    }

    # Return a formatted and normalized object of Step details
    return_stage_object(elem) := output if {
    	stage := return_resources_with_template(elem)
        output := object.union(
        	object.remove(stage, ["spec","execution"]),
            {
            "templateRef": return_template_details(stage),
            "connectorRef": return_notated_connector(stage.spec.infrastructure.spec.connector)
        	}
        )
    }

#### END   - Pipeline Data Normalization ####

#### BEGIN - Pipeline Evaluation Methods ####

    return_template_details(eval_item) := eval_item.template.templateRef if has_key(eval_item, "template") else := "missing"

    return_notated_connector(eval_item) := eval_item.identifier if {
	    eval_item.projectIdentifier != ""
    } else := concat(".", ["org" , eval_item.identifier]) if {
    	eval_item.orgIdentifier != ""
    } else := concat(".", ["account", eval_item.identifier])

    # This method will return the formatted resource to include the ancestorial template reference into the
    # object only if the step isn't a template.  Otherwise, just return the object details for the resource
    return_resources_with_template(resource) := output if {
        formatted_resource = return_object_by_notation(resource)
        not has_key(formatted_resource, "template")
        templates = walk_document(input, "template")
        resource_template := [return_object_by_notation(template) | some template in templates; startswith(format_notated_array(resource), format_notated_array(template))]
        count(resource_template) > 0

        output = object.union(formatted_resource, {"template": resource_template[0]})
    } else := return_object_by_notation(resource)

    return_found_with_value(evaluated_step, filter_value, exact_match) := output if {
        exact_match == false
        [path, value] := walk(evaluated_step)
        contains(value, filter_value)
        output = {"match": exact_match, "value": value, "key": path[count(path) - 1], "filter": filter_value, "path": format_notated_array(path)}
    } else := output if {
        [path, value] := walk(evaluated_step)
        value == filter_value
        output = {"match": exact_match, "value": value, "key": path[count(path) - 1], "filter": filter_value, "path": format_notated_array(path)}
    } else := {}


#### END   - Pipeline Evaluation Methods ####

#### BEGIN - Policy Helper Functions ####

    # This method will recursively walk the entire document by parsing out each key and compares it against the
    # key type requested.  Upon a pattern match, an array of each path segment is sent back
    walk_document(eval_doc, eval_type) = {final_path |
        [path, value] := walk(eval_doc)
        obj_type := path[count(path) - 1]
        obj_type == eval_type

        value != "REGO requires we use any declared variable so this is a workaround"

        final_path := [elem | some elem in path]
    }

    # Collapse a path segment array into an easy to manage dot notation string
    format_notated_array(path) := output if {
        output := concat(".", [format_notation(elem) | some elem in array.slice(path, 0, count(path) - 1)])
    }

    # Rego does not like to combine integers into a string when concatenating.  This will ensure that the
    # number is formatted as a string using a base10 eval
    format_notation(eval_elem) := format_int(eval_elem, 10) if is_number(eval_elem) else := eval_elem

    # Query the source document from `input` to search for the value at the provided path.
    # Note: The path variable must be an array of path segments
    return_object_by_notation(path) := object.get(input, path, {})

    array_contains(arr, elem) if {
        arr[_] = elem
    }

    has_key(x, k) if {
        _ = x[k]
    }

#### END   - Policy Helper Functions ####
