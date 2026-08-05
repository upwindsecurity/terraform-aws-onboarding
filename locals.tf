locals {
  # The upwind_version is defined as part of the release management and is used for version identification.
  # It must be maintained.
  upwind_version = "TF-3.0.1"

  # The upwind_trust_arn is included in the trusted identity of roles which can be assumed by the Upwind SaaS.
  upwind_trusted_arn = "arn:aws:iam::${var.upwind_trusted_account_id}:root"

  # The following conditional expressions are used when determining which resources can be included in each account.

  # Resolved resource names
  suffix                                      = var.role_name_suffix != null ? "-${var.role_name_suffix}" : ""
  organization_account_service_role_name      = "${var.organization_role_name}${local.suffix}"
  account_service_role_name                   = "${var.account_service_role_name}${local.suffix}"
  cloudscanner_admin_role_name                = "${var.cloudscanner_administration_role_name}${local.suffix}"
  cloudscanner_execution_role_name            = "${var.cloudscanner_execution_role_name}${local.suffix}"
  cloudscanner_secret_name                    = "${var.credentials_secret_name_prefix}${var.cloudscanner_secret_name}${local.suffix}"
  cloudscanner_saas_customer_assume_role_name = "${var.cloudscanner_saas_customer_assume_role_name}${local.suffix}"

  # Create managed policy names
  account_service_role_cloudformation_policy_name          = "${var.account_service_cloudformation_policy_name}${local.suffix}"
  account_service_role_cloudscanner_ec2_policy_name        = "${var.account_service_cloudscanner_ec2_policy_name}${local.suffix}"
  account_service_role_cloudscanner_policy_name            = "${var.account_service_cloudscanner_policy_name}${local.suffix}"
  account_service_cloudscanner_ec2_network_policy_name     = "${var.account_service_cloudscanner_ec2_network_policy_name}${local.suffix}"
  account_service_agentless_k8s_access_entries_policy_name = "${var.account_service_agentless_k8s_access_entries_policy_name}${local.suffix}"
  account_service_agentless_k8s_ssm_policy_name            = "${var.account_service_agentless_k8s_ssm_policy_name}${local.suffix}"

  # Shared DSPM RDS managed-policy names (mirror the CloudFormation v2 ManagedPolicyName values).
  cloudscanner_dspm_rds_policy_name            = "UpwindCloudScannerDspmRdsPolicy${local.suffix}"
  cloudscanner_dspm_rds_vpc_access_policy_name = "UpwindCloudScannerDspmRdsVpcAccessPolicy${local.suffix}"

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

  # SaaS mode conditions
  condition_is_saas_mode                = var.is_saas
  condition_create_customer_assume_role = local.condition_is_saas_mode && local.condition_is_orchestrator_account

  # DSPM RDS scanning enablement (mirrors the execution-role module): the feature flag gated by an optional
  # per-account allowlist. Drives the shared DSPM RDS managed policy and its role attachments.
  dspm_rds_account_allowed = (
    length(var.upwind_feature_dspm_rds_account_allowlist) == 0 ||
    contains(var.upwind_feature_dspm_rds_account_allowlist, data.aws_caller_identity.current.account_id)
  )
  dspm_rds_enabled = var.upwind_feature_dspm_rds_enabled && local.dspm_rds_account_allowed

  # Default the SaaS trusted account to the general Upwind trusted account if not explicitly set.
  saas_trusted_account_id = coalesce(var.cloudscanner_saas_trusted_account_id, var.upwind_trusted_account_id)

  # Condition to determine if CloudScanner secret should be created.
  # Not created in SaaS mode (Upwind manages the CloudScanner and its credentials).

  # Condition to determine if CloudScanner should be created
  condition_create_cloudscanner_secret = alltrue([
    local.condition_is_orchestrator_account,
    !local.condition_is_saas_mode,
    var.upwind_cloudscanner_auth_secret_arn == null
  ])

  # ---------------------------------------------
  # CloudScanner auth secret resolution logic
  # ---------------------------------------------

  condition_cloudscanner_client_id_provided = (
    var.upwind_cloudscanner_auth_client_id != null &&
    var.upwind_cloudscanner_auth_client_id != ""
  )

  condition_cloudscanner_secret_value_provided = (
    var.upwind_cloudscanner_auth_secret_value != null &&
    var.upwind_cloudscanner_auth_secret_value != ""
  )

  condition_cloudscanner_use_arn = (
    var.upwind_cloudscanner_auth_secret_arn != null &&
    var.upwind_cloudscanner_auth_secret_arn != ""
  )

  condition_cloudscanner_use_inline = (
    local.condition_cloudscanner_client_id_provided &&
    local.condition_cloudscanner_secret_value_provided
  )

  condition_cloudscanner_partial_inline = (
    local.condition_cloudscanner_client_id_provided !=
    local.condition_cloudscanner_secret_value_provided
  )

  condition_cloudscanner_has_any_secret_config = (
    local.condition_cloudscanner_use_arn ||
    local.condition_cloudscanner_client_id_provided ||
    local.condition_cloudscanner_secret_value_provided
  )

  condition_cloudscanner_invalid_both_provided = (
    local.condition_cloudscanner_use_arn &&
    local.condition_cloudscanner_use_inline
  )
}