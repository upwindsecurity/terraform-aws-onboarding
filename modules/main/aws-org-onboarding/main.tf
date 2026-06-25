# This module can be applied to each AWS account within the organisations seperately,
# and will create IAM roles and resources for each account as described in the README.

data "aws_caller_identity" "current" {}

# The Org discovery only needs to be created in the management account
module "org_discovery_role" {
  count = local.condition_is_management_account ? 1 : 0

  source = "./modules/iam_org_discovery_role"

  trusted_arn                                 = local.upwind_trusted_arn
  external_id                                 = var.external_id
  org_discovery_role_name                     = local.organization_account_service_role_name
  orchestrator_account_id                     = var.orchestrator_account_id
  account_service_role_name                   = local.account_service_role_name
  cloudscanner_admin_role_name                = local.cloudscanner_admin_role_name
  cloudscanner_execution_role_name            = local.cloudscanner_execution_role_name
  upwind_feature_dspm_enabled                 = var.upwind_feature_dspm_enabled
  is_saas_mode                                = local.condition_is_saas_mode
  cloudscanner_saas_customer_assume_role_name = local.condition_is_saas_mode ? local.cloudscanner_saas_customer_assume_role_name : null
  upwind_cloudscanner_management_enabled      = var.upwind_cloudscanner_management_enabled
  custom_tags                                 = var.custom_tags
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
  # In SaaS mode the admin role and management policies are not created, so apply_for_orchestrator_account is false.
  apply_for_orchestrator_account = local.condition_is_orchestrator_account && !local.condition_is_saas_mode

  # Provide conditional features
  upwind_feature_dspm_enabled                       = var.upwind_feature_dspm_enabled
  upwind_cloudscanner_management_enabled            = var.upwind_cloudscanner_management_enabled
  upwind_include_ec2_network_management_permissions = var.upwind_include_ec2_network_management_permissions

  # Agentless Kubernetes
  upwind_agentless_k8s_access_entries_enabled              = var.upwind_agentless_k8s_access_entries_enabled
  upwind_agentless_k8s_ssm_enabled                         = var.upwind_agentless_k8s_ssm_enabled
  upwind_agentless_k8s_eks_admin_view_policy_enabled       = var.upwind_agentless_k8s_eks_admin_view_policy_enabled
  upwind_agentless_k8s_account_whitelist                   = var.upwind_agentless_k8s_account_whitelist
  current_account_id                                       = data.aws_caller_identity.current.account_id
  account_service_agentless_k8s_access_entries_policy_name = local.account_service_agentless_k8s_access_entries_policy_name
  account_service_agentless_k8s_ssm_policy_name            = local.account_service_agentless_k8s_ssm_policy_name

  # SaaS mode tags
  is_saas_mode                                = local.condition_is_saas_mode
  cloudscanner_saas_customer_assume_role_name = local.condition_create_customer_assume_role ? local.cloudscanner_saas_customer_assume_role_name : null
}

# Create the CloudScanner admin role. This will be in the orchestrator account.
module "cloudscanner_admin_role" {
  count = (local.condition_is_orchestrator_account && !local.condition_is_saas_mode) ? 1 : 0

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

  # SaaS mode trust policy
  is_saas_mode                                = local.condition_is_saas_mode
  cloudscanner_saas_customer_assume_role_name = local.cloudscanner_saas_customer_assume_role_name
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

# In SaaS mode, create the customer assume role in the orchestrator account.
# Upwind's SaaS account assumes this role to perform scanning operations.
module "cloudscanner_saas_customer_assume_role" {
  count = local.condition_create_customer_assume_role ? 1 : 0

  source = "./modules/iam_cloudscanner_saas_customer_assume_role"

  role_name                        = local.cloudscanner_saas_customer_assume_role_name
  saas_trusted_account_id          = local.saas_trusted_account_id
  external_id                      = var.external_id
  cloudscanner_execution_role_name = local.cloudscanner_execution_role_name
  custom_tags                      = var.custom_tags
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

resource "null_resource" "validate_cloudscanner_auth" {
  lifecycle {

    # Only validate if orchestrator is provided AND not in SaaS mode
    precondition {
      condition = (
        local.condition_is_saas_mode ||
        !local.condition_has_orchestrator_account_id ||
        local.condition_cloudscanner_has_any_secret_config
      )
      error_message = "CloudScanner auth is required when an orchestrator account is provided. Provide either a secret ARN or client_id and client_secret."
    }

    # If NOT using ARN → client_id must exist when secret exists
    precondition {
      condition = (
        local.condition_is_saas_mode ||
        !local.condition_has_orchestrator_account_id ||
        local.condition_cloudscanner_use_arn ||
        !local.condition_cloudscanner_secret_value_provided ||
        local.condition_cloudscanner_client_id_provided
      )
      error_message = "CloudScanner auth: client_id is missing. Client Secret and ID must be provided."
    }

    # If NOT using ARN → client_secret must exist when client_id exists
    precondition {
      condition = (
        local.condition_is_saas_mode ||
        !local.condition_has_orchestrator_account_id ||
        local.condition_cloudscanner_use_arn ||
        !local.condition_cloudscanner_client_id_provided ||
        local.condition_cloudscanner_secret_value_provided
      )
      error_message = "CloudScanner auth: client_secret is missing. Client Secret and ID must be provided."
    }

    # Cannot provide both ARN and inline
    precondition {
      condition = (
        local.condition_is_saas_mode ||
        !local.condition_has_orchestrator_account_id ||
        !local.condition_cloudscanner_invalid_both_provided
      )
      error_message = "CloudScanner auth: provide either a secret ARN OR client_id/client_secret, not both."
    }

    # Prevent partial inline ONLY when not using ARN
    precondition {
      condition = (
        local.condition_is_saas_mode ||
        !local.condition_has_orchestrator_account_id ||
        local.condition_cloudscanner_use_arn ||
        !local.condition_cloudscanner_partial_inline
      )
      error_message = "CloudScanner auth: both client_id and client_secret must be provided together."
    }
  }
}

resource "null_resource" "validate_saas_config" {
  lifecycle {
    precondition {
      condition     = !local.condition_is_saas_mode || var.orchestrator_account_id != null
      error_message = "orchestrator_account_id is required when is_saas = true."
    }
  }
}

