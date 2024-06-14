terraform {
  required_providers {
    harness = {
      source  = "harness/harness"
    }
  }
}

# Using next gen. Auth configured via Env vars (HARNESS_ACCOUNT_ID,HARNESS_ENDPOINT,HARNESS_PLATFORM_API_KEY). 
# Refer https://registry.terraform.io/providers/harness/harness/latest/docs#optional
provider "harness" {
}