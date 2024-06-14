resource "harness_platform_resource_group" "test" {
  account_id = var.account_id
  identifier = var.identifier
  name       = var.name

  allowed_scope_levels = var.allowed_scope_levels
  dynamic "included_scopes" {
    for_each = var.included_scopes
    content {
      filter     = included_scopes.value.filter
      account_id = included_scopes.value["account_id"]
    }
  }
  dynamic "resource_filter" {
    for_each = var.resource_filter
    content {
      include_all_resources = resource_filter.value.include_all_resources
      dynamic "resources" {
        for_each = resource_filter.value.resources
        content {
          resource_type = resources.value.resource_type
          dynamic "attribute_filter" {
            for_each = resources.value.attribute_filter
            content {
              attribute_name   = attribute_filter.value.attribute_name
              attribute_values = attribute_filter.value.attribute_values
            }
          }
        }
      }
    }
  }
}