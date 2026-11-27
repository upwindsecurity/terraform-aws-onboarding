locals {
  upwind_version = "TF-4.12.0"

  # Prefix applied to the role-name discovery tag values so CloudScanner reconstructs the correct ARN when a
  # custom IAM path is set. Empty for the default path ("/") to preserve the legacy bare role-name values.
  role_name_path_prefix = var.iam_role_path == "/" ? "" : var.iam_role_path

  # Resolve the optional permissions boundary. A value beginning with "arn:" is used verbatim; a bare
  # policy name/path is expanded to a full ARN for this account. Null when no boundary was supplied.
  permissions_boundary_arn = (
    var.permissions_boundary == null ? null :
    can(regex("^arn:", var.permissions_boundary)) ? var.permissions_boundary :
    "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/${var.permissions_boundary}"
  )

  # The orchestrator account id as an empty string when none was supplied.
  orchestrator_account_id = var.orchestrator_account_id == null ? "" : var.orchestrator_account_id

  # The default or an additional orchestrator account, where the onboarding settings parameter is written.
  is_orchestrator_account = var.current_account_id == null ? false : (
    var.current_account_id == local.orchestrator_account_id ||
    contains(var.additional_orchestrator_account_ids, var.current_account_id)
  )

  # The onboarding settings parameter path, with the role name suffix as a further path segment when one is used.
  ssm_parameter_prefix = var.role_name_suffix != "" ? "${var.ssm_parameter_prefix}/${var.role_name_suffix}" : var.ssm_parameter_prefix

  # DSPM and DSPM RDS for this account, limited by the optional account allowlists.
  dspm_enabled = var.upwind_feature_dspm_enabled && (
    length(var.upwind_feature_dspm_account_whitelist) == 0 || (
      var.current_account_id != null &&
      contains(var.upwind_feature_dspm_account_whitelist, var.current_account_id)
    )
  )

  dspm_rds_enabled = var.upwind_feature_dspm_rds_enabled && (
    length(var.upwind_feature_dspm_rds_account_allowlist) == 0 || (
      var.current_account_id != null &&
      contains(var.upwind_feature_dspm_rds_account_allowlist, var.current_account_id)
    )
  )

  agentless_k8s_account_allowed = (
    length(var.upwind_agentless_k8s_account_whitelist) == 0 || (
      var.current_account_id != null &&
      contains(var.upwind_agentless_k8s_account_whitelist, var.current_account_id)
    )
  )

  agentless_k8s_access_entries_enabled = var.upwind_agentless_k8s_access_entries_enabled && local.agentless_k8s_account_allowed

  agentless_k8s_ssm_enabled = var.upwind_agentless_k8s_ssm_enabled && local.agentless_k8s_account_allowed
}
