account_id = "<ACCOUNT ID>"
org_name   = "Sandbox-TF"
org_id     = "sandboxtf"
org_tag    = ["type:sandbox", "env:demo"]

resource_group = [
  {
    allowed_scope_levels = ["account"]
    name                 = "resource group 1"
    identifier           = "resource-group-1"
    included_scopes = [
      {
        filter     = "EXCLUDING_CHILD_SCOPES"
        account_id = "<ACCOUNT ID>"
      },
    ]
    resource_filter = [
      {
        include_all_resources = false
        resources = [
          {
            resource_type = "CONNECTOR"
            attribute_filter = [
              {
                attribute_name   = "category"
                attribute_values = ["CLOUD_COST"]
              }
            ]
          }
        ]
      }
    ]
  },
  {
    allowed_scope_levels = ["account"]
    name                 = "resource group2"
    identifier           = "resource-group-2"
    included_scopes = [
      {
        filter     = "EXCLUDING_CHILD_SCOPES"
        account_id = "account_id"
      },
    ]
    resource_filter = [
      {
        include_all_resources = false
        resources = [
          {
            resource_type    = "CONNECTOR"
            attribute_filter = []
          }
        ]
      }
    ]
  },
  {
    allowed_scope_levels = ["account"]
    name                 = "resource group 3"
    identifier           = "resource-group-3"
    included_scopes      = []
    resource_filter = [
      {
        include_all_resources = false
        resources = [
          {
            resource_type    = "CONNECTOR"
            attribute_filter = []
          }
        ]
      }
    ]
  }
]