locals {
  upwind_version = "TF-2.1.16"
  aws_account_id = data.aws_caller_identity.current.account_id

  dspm_account_allowed = (
    length(var.upwind_feature_dspm_account_whitelist) == 0 ||
    contains(var.upwind_feature_dspm_account_whitelist, local.aws_account_id)
  )

  dspm_enabled = var.upwind_feature_dspm_enabled && local.dspm_account_allowed
}
