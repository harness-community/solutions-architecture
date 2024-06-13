# Policy: Recursively Restrict Secrets except in valid Template
package pipeline

import future.keywords.if
import future.keywords.in

#### BEGIN - Policy Controls ####
    # Steps that should not used in pipelines
    forbidden_secrets = ["account.default_github_access"]

    # Approved Templates
    approved_templates = ["Valid_CI"]

    # Filter resources by type
    filter_stages = false
    filter_steps  = false


#### END   - Policy Controls ####

#### BEGIN - Pipeline Step Type Validation ####

    # Restrict Forbidden secrets from being used
    deny[msg] {
#         secret = [object.union(return_resources_with_template(elem), return_stage_object(elem)) | some elem in walk_document(input, "tokenRef")][_]
		secret = [return_resources_with_template(elem)  | some elem in walk_document(input, "tokenRef")][_]

        msg := sprintf("Failed: %s", [secret] )
#         notated_secret = return_notated_secret(secret)
#         not array_contains(approved_templates, return_template_details(secret))
# 		array_contains(forbidden_secrets, notated_secret)
#         msg := sprintf("Failed: The pipeline '%s' has a Harness secret Definition '%s' that is forbidden and only valid when used with an approved template %s. ", [input.pipeline.name, notated_secret, approved_templates])
    }

#### END   - Pipeline Step Type Validation ####

#### BEGIN - Pipeline Data Normalization ####
    return_template_details(eval_item) := eval_item.template.templateRef if has_key(eval_item, "template") else := "missing"

    return_notated_secret(eval_item) := eval_item.identifier if {
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

    # Each layer is read from the top of the `input` resource and therefore, the stage details should be in the
    # stage key based on the 3rd elem in the elem variable (which should be path segments from the `walk_document`
    # function)
    return_stage_object(elem) := output if {
        output := {"stage": return_object_by_notation(["pipeline", "stages", elem[2], "stage"])}
    } else := {"stage": {}}

    # Collapse a path segment array into an easy to manage dot notation string
    format_notated_array(path) := output if {
        output := concat(".", [format_notation(elem) | some elem in array.slice(path, 0, count(path) - 1)])
    }

    # Rego does not like to combine integers into a string when concatenating.  This will ensure that the
    # number is formatted as a string using a base10 eval
    format_notation(eval_elem) := format_int(eval_elem, 10) if is_number(eval_elem)

    else := eval_elem

    # Query the source document from `input` to search for the value at the provided path.
    # Note: The path variable must be an array of path segments
    return_object_by_notation(path) := object.get(input, path, {})

    # Return the filtered dat
    return_filtered_data(eval_path) if {
        filter_steps
    	filter_stages
        array_contains(eval_path, "step")
    } else if {
    	filter_stages
        not filter_steps
        array_contains(eval_path, "stage")
    } else if {
    	not filter_stages
        not filter_steps
    }

#### END   - Pipeline Data Normalization ####

#### BEGIN - Policy Helper Functions ####

    # This method will recursively walk the entire document by parsing out each key and compares it against the
    # key type requested.  Upon a pattern match, an array of each path segment is sent back
    walk_document(eval_doc, eval_type) = {final_path |
        [path, value] := walk(eval_doc)
        obj_type := path[count(path) - 1]
        obj_type == eval_type
        return_filtered_data(path)

        value != "REGO requires we use any declared variable so this is a workaround"

        final_path := [elem | some elem in path]
    }

    array_contains(arr, elem) if {
        arr[_] = elem
    }

    has_key(x, k) if {
        _ = x[k]
    }

#### END   - Policy Helper Functions ####
