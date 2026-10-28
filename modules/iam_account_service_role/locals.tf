locals {
  upwind_version = "TF-4.6.0"

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

  common_tags = merge(var.custom_tags, {
    "upwind:aws:Component"      = "Onboarding",
    "upwind:aws:ReleaseVersion" = local.upwind_version
  })

  upwind_cfn_sources = [
    "https://s3.amazonaws.com/${var.upwind_cfn_bucket}/cfn/templates/*",
    "https://s3.us-east-1.amazonaws.com/${var.upwind_cfn_bucket}/cfn/templates/*"
  ]

  agentless_k8s_account_allowed = (
    length(var.upwind_agentless_k8s_account_whitelist) == 0 || (
      var.current_account_id != null &&
      contains(var.upwind_agentless_k8s_account_whitelist, var.current_account_id)
    )
  )

  agentless_k8s_access_entries_enabled = var.upwind_agentless_k8s_access_entries_enabled && local.agentless_k8s_account_allowed

  agentless_k8s_ssm_enabled = var.upwind_agentless_k8s_ssm_enabled && local.agentless_k8s_account_allowed
}
