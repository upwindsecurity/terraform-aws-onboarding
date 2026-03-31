provider "aws" {}


# Example usage of the AWS Org onboarding module.
# This module can be applied to multiple accounts to create the necessary resources. It is expected that the module will be run
# by a deployment tool such as terraform - capable of applying the terraform to multiple accounts.
module "upwind_org_account_onboarding" {
  source = "../../modules/aws-org-onboarding"

  # Variables required when performing the Org Discovery role registrations
  upwind_region                         = "us" # Default value - not required for US region
  upwind_org_register_auth_client_id    = "dfsfsfsdfsfsdf"
  upwind_org_register_auth_secret_value = "sfsfsfsfsdsdf"
  upwind_organization_id                = "org_2rNHQxTwevbcc7a2" # Required for API access 
  #  upwind_disable_org_discovery_role_registration = true

  external_id                         = "1123345"
  management_account_id               = "350776374247"
  orchestrator_account_id             = "097423745500"
  install_roles_in_management_account = true

  # The role name suffix is a random set of characters that will be appended to each resource id to ensure uniqueness.
  role_name_suffix = "abcd1234"

  # The credentails can either be provided as values or an ARN
  upwind_cloudscanner_auth_client_id    = "afsfsf"
  upwind_cloudscanner_auth_secret_value = "sdfsfsf"

  # Setting the following variables for dev configs would be useful. These will be set by the release mgmt for dev though.
  upwind_auth_endpoint        = "https://auth.upwind.dev"
  upwind_integration_endpoint = "https://integration.upwind.dev"
  upwind_trusted_account_id   = "027696145188"

  account_service_cloudformation_policy_name = "apple"
  account_service_cloudscanner_policy_name   = "banana"
}