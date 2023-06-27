# Policy: Recursively Restrict Stage Connectors except in valid Template
package pipeline

import future.keywords.if
import future.keywords.in

#### BEGIN - Policy Controls ####
    # Steps that should not used in pipelines
    forbidden_connectors = ["account.default_github_access", "account.DockerHub", "account.harnessImageExternal", "org.laptop"]

    # Approved Templates
    approved_templates = ["Valid_CI", "account.CI_Verification"]


#### END   - Policy Controls ####

#### BEGIN - Pipeline Step Type Validation ####

    # Restrict Forbidden Connectors from being used
    deny[msg] {
        pipeline_details = return_pipeline_object(input.pipeline)
	    resource := [elem | some elem in walk_document(input, "stage")][_]

        stage = object.union(return_stage_object(resource), pipeline_details)

        # Validate the templates for the Step, Stage, and Pipeline to determine if the value matches approved templates
        verify_step_templates(stage)

        # If no approved template, then we need to evaluate the connectorRef for the stage to determine if there is
        # a forbidden connector in use
        array_contains(forbidden_connectors, stage.connectorRef)

        msg := sprintf("Failed: The stage '%s' has a Harness Connector Definition '%s' that is forbidden and only valid when used with an approved template %s. ", [stage.name, stage.connectorRef, approved_templates])
    }

    # Verify the templates based on the hierachy of the pipeline
    verify_step_templates(resource) if {
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
        output := {
            "identifier": stage.identifier,
            "name": stage.name,
            "templateRef": return_template_details(stage),
            "connectorRef": return_notated_connector(stage.spec.infrastructure.spec.connector)
        }
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
