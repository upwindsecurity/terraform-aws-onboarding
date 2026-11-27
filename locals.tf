locals {
  # The upwind_version is stamped by scripts/inject-version.sh as part of the release process (the registry version).
  upwind_version = "TF-4.12.0"

  # The upwind_trust_arn is included in the trusted identity of roles which can be assumed by the Upwind SaaS.
  # Upwind's account for the partition being deployed to, unless upwind_trusted_account_id overrides it.
  upwind_trusted_account_id = coalesce(var.upwind_trusted_account_id, local.partition.trusted_account)

  # The following conditional expressions are used when determining which resources can be included in each account.

  # Resolved resource names
  suffix                                 = var.role_name_suffix != null ? "-${var.role_name_suffix}" : ""
  organization_account_service_role_name = "${var.organization_role_name}${local.suffix}"
  account_service_role_name              = "${var.account_service_role_name}${local.suffix}"
  cloudscanner_admin_role_name           = "${var.cloudscanner_administration_role_name}${local.suffix}"
  cloudscanner_admin_role_profile_name   = "${var.cloudscanner_administration_role_profile_name}${local.suffix}"
  cloudscanner_execution_role_name       = "${var.cloudscanner_execution_role_name}${local.suffix}"
  cloudscanner_secret_name               = "${var.credentials_secret_name_prefix}${var.cloudscanner_secret_name}${local.suffix}"
  # The cloudscanner_secret_name default, which is the fixed secret base name in the CloudFormation templates.
  default_cloudscanner_secret_name            = "/cloudscanner-credentials"
  cloudscanner_saas_customer_assume_role_name = "${var.cloudscanner_saas_customer_assume_role_name}${local.suffix}"

  # Create managed policy names
  account_service_role_cloudformation_policy_name          = "${var.account_service_cloudformation_policy_name}${local.suffix}"
  account_service_role_cloudscanner_ec2_policy_name        = "${var.account_service_cloudscanner_ec2_policy_name}${local.suffix}"
  account_service_role_cloudscanner_policy_name            = "${var.account_service_cloudscanner_policy_name}${local.suffix}"
  account_service_cloudscanner_ec2_network_policy_name     = "${var.account_service_cloudscanner_ec2_network_policy_name}${local.suffix}"
  account_service_agentless_k8s_access_entries_policy_name = "${var.account_service_agentless_k8s_access_entries_policy_name}${local.suffix}"
  account_service_agentless_k8s_ssm_policy_name            = "${var.account_service_agentless_k8s_ssm_policy_name}${local.suffix}"

  # DSPM RDS managed-policy names (the CloudFormation ManagedPolicyName values).
  cloudscanner_dspm_rds_policy_name           = "${var.cloudscanner_dspm_rds_policy_name}${local.suffix}"
  cloudscanner_dspm_rds_execution_policy_name = "${var.cloudscanner_dspm_rds_execution_policy_name}${local.suffix}"

  # The SSM path of the onboarding settings: the prefix, plus the role name suffix as a further path segment.
  ssm_parameter_prefix = var.role_name_suffix != null ? "${var.ssm_parameter_prefix}/${var.role_name_suffix}" : var.ssm_parameter_prefix

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

  # Additional orchestrator accounts augment the default orchestrator account (orchestrator_account_id).
  condition_is_additional_orchestrator_account = contains(var.additional_orchestrator_account_ids, data.aws_caller_identity.current.account_id)
  condition_is_any_orchestrator_account        = local.condition_is_orchestrator_account || local.condition_is_additional_orchestrator_account

  # SaaS mode conditions
  condition_is_saas_mode                = var.is_saas
  condition_create_customer_assume_role = local.condition_is_saas_mode && local.condition_is_orchestrator_account

  # The CloudScanner admin role, secret and management permissions go to every orchestrator account, except the
  # default one in SaaS mode (Upwind runs the CloudScanners there through the customer assume role).
  condition_create_orchestration_account_resources = local.condition_is_any_orchestrator_account && (!local.condition_is_saas_mode || !local.condition_is_orchestrator_account)

  # The single account onboarding Lambda is only relevant for Upwind managed organizations, and can be opted out of
  condition_create_single_account_onboarding_lambda = var.is_virtual_organization && var.upwind_single_account_onboarding_lambda_enabled

  # DSPM (S3) enablement (mirrors the execution-role module), recorded in the onboarding settings.
  dspm_account_allowed = (
    length(var.upwind_feature_dspm_account_whitelist) == 0 ||
    contains(var.upwind_feature_dspm_account_whitelist, data.aws_caller_identity.current.account_id)
  )
  dspm_enabled = var.upwind_feature_dspm_enabled && local.dspm_account_allowed

  # DSPM RDS scanning enablement (mirrors the execution-role module): the feature flag gated by an optional
  # per-account allowlist. Drives the DSPM RDS managed policies and their role attachments.
  dspm_rds_account_allowed = (
    length(var.upwind_feature_dspm_rds_account_allowlist) == 0 ||
    contains(var.upwind_feature_dspm_rds_account_allowlist, data.aws_caller_identity.current.account_id)
  )
  dspm_rds_enabled = var.upwind_feature_dspm_rds_enabled && local.dspm_rds_account_allowed

  # The Upwind SaaS account: required in SaaS mode (see null_resource.validate_saas_config).
  saas_trusted_account_id = var.cloudscanner_saas_trusted_account_id

  # Condition to determine if CloudScanner secret should be created: wherever the admin role is, unless an ARN
  # was given. Not created in the default orchestrator account in SaaS mode (Upwind manages its credentials).
  condition_create_cloudscanner_secret = alltrue([
    local.condition_create_orchestration_account_resources,
    var.upwind_cloudscanner_auth_secret_arn == null
  ])

  # The secret ARN supplied by the caller, empty when none was given.
  given_cloudscanner_secret_arn = var.upwind_cloudscanner_auth_secret_arn != null ? var.upwind_cloudscanner_auth_secret_arn : ""

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

  condition_create_secret_for_single_account_onboarding = (
    local.condition_cloudscanner_use_inline &&
    local.condition_create_single_account_onboarding_lambda
  )
}
