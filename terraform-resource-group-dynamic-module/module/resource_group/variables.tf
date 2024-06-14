variable "account_id" {
  type        = string
  description = "Account id"
}
variable "identifier" {
  type        = string
  description = "identifier"
}

variable "name" {
  type        = string
  description = "name"
}

variable "allowed_scope_levels" {
  type        = list(string)
  description = "Allowed scope levels"
}

variable "included_scopes" {
  type = set(object({
    filter     = string
    account_id = string
  }))
  description = "included scopes"
}

variable "resource_filter" {
  type = list(object({
    include_all_resources = bool
    resources = set(object({
      resource_type = string
      attribute_filter = list(object({
        attribute_name   = string
        attribute_values = list(string)
      }))
    }))
  }))
  description = "resource filter"
}