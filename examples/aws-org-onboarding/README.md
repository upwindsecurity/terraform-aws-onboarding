# AWS Organization Onboarding Example

This example demonstrates how to use the
[aws-org-onboarding](https://github.com/upwindsecurity/terraform-aws-onboarding/tree/main/modules/aws-org-onboarding)
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
