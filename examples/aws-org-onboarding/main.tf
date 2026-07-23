provider "aws" {}

# Example usage of the AWS Org onboarding module.
# This module can be applied to multiple accounts to create the necessary resources. It is expected that the module will be run
# by a deployment tool such as Terragrunt - capable of applying the terraform to multiple accounts.
module "upwind_org_account_onboarding" {
  source = "../../modules/main/aws-org-onboarding"

  # The external ID is provided by Upwind as part of the onboarding process.
  external_id                         = "F083B753-06B5-40B2-BE41-4035D6A7B6C7"
  management_account_id               = "098765432109"
  orchestrator_account_id             = "123456789012"
  install_roles_in_management_account = true

  # The role name suffix is a random set of characters that will be appended to each resource id to ensure uniqueness.
  role_name_suffix = "abcd1234"

  # The credentials can either be provided as values or as an existing secret ARN
  # (see the upwind_cloudscanner_auth_secret_arn variable).
  upwind_cloudscanner_auth_client_id    = "<<cloudscanner-client-id>>"
  upwind_cloudscanner_auth_secret_value = "<<cloudscanner-client-secret>>"

  # Optionally override the default resource names to align with your own naming conventions.
  # The same names must be used consistently across all accounts.
  account_service_cloudformation_policy_name = "MyCloudFormationPolicyName"
  account_service_cloudscanner_policy_name   = "MyCloudScannerPolicyName"
}
