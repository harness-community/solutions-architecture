data "harness_platform_organization" "default" {
    id = "default"
}

data "harness_platform_project" "default" {
    id = "Default_Project_1663065042038"
    org_id = data.harness_platform_organization.default.id
}


