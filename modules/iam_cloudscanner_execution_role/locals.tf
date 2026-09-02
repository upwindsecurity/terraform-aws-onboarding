locals {
  upwind_version = "TF-4.2.1"
  aws_account_id = data.aws_caller_identity.current.account_id

  # Resolve the optional permissions boundary. A value beginning with "arn:" is used verbatim; a bare
  # policy name/path is expanded to a full ARN for this account. Null when no boundary was supplied.
  permissions_boundary_arn = (
    var.permissions_boundary == null ? null :
    can(regex("^arn:", var.permissions_boundary)) ? var.permissions_boundary :
    "arn:${data.aws_partition.current.partition}:iam::${local.aws_account_id}:policy/${var.permissions_boundary}"
  )

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
