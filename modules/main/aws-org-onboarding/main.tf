# This module can be applied to each AWS account within the organisations seperately,
# and will create IAM roles and resources for each account as described in the README.

data "aws_caller_identity" "current" {}

# The Org discovery only needs to be created in the management account
module "org_discovery_role" {
  count = local.condition_is_management_account ? 1 : 0

  source = "./modules/iam_org_discovery_role"

  trusted_arn                      = local.upwind_trusted_arn
  external_id                      = var.external_id
  org_discovery_role_name          = local.organization_account_service_role_name
  orchestrator_account_id          = var.orchestrator_account_id
  account_service_role_name        = local.account_service_role_name
  cloudscanner_admin_role_name     = local.cloudscanner_admin_role_name
  cloudscanner_execution_role_name = local.cloudscanner_execution_role_name
  upwind_feature_dspm_enabled      = var.upwind_feature_dspm_enabled
  custom_tags                      = var.custom_tags
}

# The Account Service role will be installed in all accounts but for the management account
# where it is only installed optionally.
module "account_service_role" {
  count = (!local.condition_is_management_account ||
  (local.condition_is_management_account && var.install_roles_in_management_account)) ? 1 : 0

  depends_on = [module.cloudscanner_secret]

  source = "./modules/iam_account_service_role"

  trusted_arn                      = local.upwind_trusted_arn
  external_id                      = var.external_id
  account_service_role_name        = local.account_service_role_name
  cloudscanner_admin_role_name     = local.cloudscanner_admin_role_name
  cloudscanner_execution_role_name = local.cloudscanner_execution_role_name
  custom_tags                      = var.custom_tags

  # Pass the names for the managed policies
  account_service_cloudformation_policy_name           = local.account_service_role_cloudformation_policy_name
  account_service_cloudscanner_ec2_policy_name         = local.account_service_role_cloudscanner_ec2_policy_name
  account_service_cloudscanner_policy_name             = local.account_service_role_cloudscanner_policy_name
  account_service_cloudscanner_ec2_network_policy_name = local.account_service_cloudscanner_ec2_network_policy_name

  # Set the secret - either to the created secret or the ARN provided
  cloudscanner_secret_arn = local.condition_create_cloudscanner_secret ? one(module.cloudscanner_secret[*]).secret.arn : var.upwind_cloudscanner_auth_secret_arn

  # The management account could be chosen as the orchestrator account (not recommended), so the role should be
  # created with the additional permissions
  apply_for_orchestrator_account = local.condition_is_orchestrator_account

  # Provide conditional features
  upwind_feature_dspm_enabled                       = var.upwind_feature_dspm_enabled
  upwind_cloudscanner_management_enabled            = var.upwind_cloudscanner_management_enabled
  upwind_include_ec2_network_management_permissions = var.upwind_include_ec2_network_management_permissions
}

# Create the CloudScanner admin role. This will be in the orchestrator account.
module "cloudscanner_admin_role" {
  count = local.condition_is_orchestrator_account ? 1 : 0

  source = "./modules/iam_cloudscanner_admin_role"

  cloudscanner_admin_role_name     = local.cloudscanner_admin_role_name
  cloudscanner_execution_role_name = local.cloudscanner_execution_role_name
  custom_tags                      = var.custom_tags

  # Set the secret - either to the created secret or the ARN provided
  cloudscanner_secret_arn = local.condition_create_cloudscanner_secret ? one(module.cloudscanner_secret[*]).secret.arn : var.upwind_cloudscanner_auth_secret_arn
}

# The CloudScanner execution role should be created in all accounts which are to be scanned. Optionally,
# this may include the management account.
module "cloudscanner_execution_role" {
  count = (local.condition_has_orchestrator_account_id &&
  (!local.condition_is_management_account || (local.condition_is_management_account && var.install_roles_in_management_account))) ? 1 : 0

  source = "./modules/iam_cloudscanner_execution_role"

  orchestrator_account_id          = var.orchestrator_account_id
  cloudscanner_admin_role_name     = local.cloudscanner_admin_role_name
  cloudscanner_execution_role_name = local.cloudscanner_execution_role_name
  custom_tags                      = var.custom_tags

  # Provide conditional features
  upwind_feature_dspm_enabled           = var.upwind_feature_dspm_enabled
  upwind_feature_dspm_account_whitelist = var.upwind_feature_dspm_account_whitelist
}

# Create the CloudScanner secret in the orchestrator account if not using a provided ARN.
# If the orchestrator account is the management account, only create the secret if the install roles
# has been configured
module "cloudscanner_secret" {
  count = local.condition_create_cloudscanner_secret ? 1 : 0

  source = "./modules/cloudscanner_auth_secret"

  secret_name       = local.cloudscanner_secret_name
  auth_client_id    = var.upwind_cloudscanner_auth_client_id
  auth_secret_value = var.upwind_cloudscanner_auth_secret_value
  custom_tags       = var.custom_tags
}

# Create the resources which will automatically register the Org role
resource "time_sleep" "wait_for_org_discovery_role_creation" {
  count = (local.condition_is_management_account && !var.upwind_disable_org_discovery_role_registration) ? 1 : 0
  depends_on = [
    module.org_discovery_role,
  ]
  create_duration = var.aws_iam_role_creation_wait_time
}

module "register_org_discovery_role" {
  count = (local.condition_is_management_account && !var.upwind_disable_org_discovery_role_registration) ? 1 : 0

  depends_on = [time_sleep.wait_for_org_discovery_role_creation]

  source                 = "./modules/register_org_role"
  upwind_organization_id = var.upwind_organization_id
  role_arn               = one(module.org_discovery_role[*]).iam_role.arn

  upwind_auth_client_id       = var.upwind_org_register_auth_client_id
  upwind_auth_secret_value    = var.upwind_org_register_auth_secret_value
  upwind_auth_secret_arn      = var.upwind_org_register_auth_secret_arn
  upwind_auth_endpoint        = var.upwind_auth_endpoint
  upwind_integration_endpoint = var.upwind_integration_endpoint
  upwind_region               = var.upwind_region
}

# Using a null resource so that we can avail of the precondition rules to
# perform extra validation when installing into the management account
resource "null_resource" "validate_management_account" {
  count = (local.condition_is_management_account) ? 1 : 0
  lifecycle {
    precondition {
      condition     = (local.condition_is_orchestrator_account && var.install_roles_in_management_account) || !local.condition_is_orchestrator_account
      error_message = "When using the Management account as the Orchestrator account, the option to install the additional roles must be enabled."
    }
  }
}
