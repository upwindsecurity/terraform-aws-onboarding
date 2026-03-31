locals {
  # The upwind_version is defined as part of the release management and is used for version identifification. 
  # It must be maintained.
  upwind_version = "VERSION_UNDEFINED"

  # The upwind_trust_arn is included in the trusted identity of roles which can be assumed by the Upwind SaaS.
  upwind_trusted_arn = "arn:aws:iam::${var.upwind_trusted_account_id}:root"

  # The following conditional expressions are used when determining which resources can be included in each account.

  # Resolved resource names
  suffix                                 = var.role_name_suffix != null ? "-${var.role_name_suffix}" : ""
  organization_account_service_role_name = "${var.organization_role_name}${local.suffix}"
  account_service_role_name              = "${var.account_service_role_name}${local.suffix}"
  cloudscanner_admin_role_name           = "${var.cloudscanner_administration_role_name}${local.suffix}"
  cloudscanner_execution_role_name       = "${var.cloudscanner_execution_role_name}${local.suffix}"
  cloudscanner_secret_name               = "${var.credentials_secret_name_prefix}${var.cloudscanner_secret_name}${local.suffix}"

  # Create managed policy names
  account_service_role_cloudformation_policy_name      = "${var.account_service_cloudformation_policy_name}${local.suffix}"
  account_service_role_cloudscanner_ec2_policy_name    = "${var.account_service_cloudscanner_ec2_policy_name}${local.suffix}"
  account_service_role_cloudscanner_policy_name        = "${var.account_service_cloudscanner_policy_name}${local.suffix}"
  account_service_cloudscanner_ec2_network_policy_name = "${var.account_service_cloudscanner_ec2_network_policy_name}${local.suffix}"

  # Condition used to determine if the module is being applied to the management account
  condition_has_management_account_id = !(var.management_account_id == null)
  condition_is_management_account = alltrue([
    local.condition_has_management_account_id,
    (data.aws_caller_identity.current.account_id == var.management_account_id)
  ])

  # Condition used to determine if the module is being applied to the orchestrator account
  condition_has_orchestrator_account_id = !(var.orchestrator_account_id == null)
  condition_is_orchestrator_account = alltrue([
    local.condition_has_orchestrator_account_id,
    (data.aws_caller_identity.current.account_id == var.orchestrator_account_id)
  ])

  # Condition to determine if CloudScanner should be created :-
  # * create the secret in the orchestrator account - only if a secret ARN has not been provided
  condition_create_cloudscanner_secret = alltrue([local.condition_is_orchestrator_account,
  var.upwind_cloudscanner_auth_secret_arn == null])
}

