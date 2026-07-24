locals {
  upwind_version = "TF-3.0.0"

  common_tags = merge(var.custom_tags, {
    "upwind:aws:Component"      = "Onboarding",
    "upwind:aws:ReleaseVersion" = local.upwind_version
  })

  upwind_cfn_sources = [
    "https://s3.amazonaws.com/get.upwind.io/cfn/templates/*",
    "https://s3.us-east-1.amazonaws.com/get.upwind.io/cfn/templates/*"
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
