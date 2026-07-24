# AWS Organization Onboarding Example

This example demonstrates how to use the
[aws-org-onboarding](https://github.com/upwindsecurity/terraform-aws-onboarding)
module to onboard the accounts of an AWS Organization into Upwind.

The module is intended to be applied to every account in the organization,
typically via a deployment tool such as Terragrunt which is capable of applying
the same configuration across multiple accounts. The module conditionally
creates the appropriate IAM roles and resources in each account based on the
account type:

- **Management account** (`management_account_id`): receives the Organization
  Discovery role, and optionally the Account Service and CloudScanner Execution
  roles when `install_roles_in_management_account` is enabled.
- **Orchestrator account** (`orchestrator_account_id`): receives the
  CloudScanner administration role and the CloudScanner credentials secret in
  addition to the standard roles.
- **All other accounts**: receive the Account Service and CloudScanner
  Execution roles.

## Example

The configuration below mirrors [`main.tf`](./main.tf) in this directory:

```hcl
provider "aws" {
  # set this to your desired region
  region = "us-east-1"
}

# Example usage of the AWS Org onboarding module.
# This module can be applied to multiple accounts to create the necessary resources. It is expected that the module will be run
# by a deployment tool such as Terragrunt - capable of applying the terraform to multiple accounts.
module "upwind_org_account_onboarding" {
  source = "upwindsecurity/onboarding/aws"
  # Get versions from https://registry.terraform.io/modules/upwindsecurity/onboarding/aws/latest
  # The root-module source exists from 4.0.0 onwards; earlier versions used
  # the //modules/aws-org-onboarding (3.x) or //modules/main/aws-org-onboarding
  # (2.x) submodule paths.
  version = "~> 4.0"

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
```

## Usage

Replace the placeholder values in `main.tf` with the values provided during the
Upwind onboarding process (external ID and CloudScanner credentials) and your
own account IDs, then run:

```shell
terraform init
terraform plan
terraform apply
```

After applying to the management account, enter the ARN reported by the
`organization_discovery_role_arn` output into the Upwind console to complete
the onboarding process.
