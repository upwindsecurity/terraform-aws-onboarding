locals {
  upwind_version = "TF-4.0.2"
  aws_account_id = data.aws_caller_identity.current.account_id

  dspm_account_allowed = (
    length(var.upwind_feature_dspm_account_whitelist) == 0 ||
    contains(var.upwind_feature_dspm_account_whitelist, local.aws_account_id)
  )

  dspm_enabled = var.upwind_feature_dspm_enabled && local.dspm_account_allowed

  dspm_rds_account_allowed = (
    length(var.upwind_feature_dspm_rds_account_allowlist) == 0 ||
    contains(var.upwind_feature_dspm_rds_account_allowlist, local.aws_account_id)
  )

  dspm_rds_enabled = var.upwind_feature_dspm_rds_enabled && local.dspm_rds_account_allowed
}
