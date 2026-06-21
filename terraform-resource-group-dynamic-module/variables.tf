variable "account_id" {
  type        = string
  description = "Account ID"
  default     = ""
}

variable "org_name" {
  type        = string
  description = "org name"
  default     = ""
}

variable "org_id" {
  type        = string
  description = "org name"
  default     = ""
}

variable "org_tag" {
  type        = list(string)
  default     = [""]
  description = "Org tags"
}

variable "resource_group" {
  type = list(object({
    name                 = string
    identifier           = string
    allowed_scope_levels = list(string)
    included_scopes = set(object({
      filter     = string
      account_id = string
    }))
    resource_filter = list(object({
      include_all_resources = bool
      resources = set(object({
        resource_type = string
        attribute_filter = list(object({
          attribute_name   = string
          attribute_values = list(string)
        }))
      }))
    }))
  }))
}