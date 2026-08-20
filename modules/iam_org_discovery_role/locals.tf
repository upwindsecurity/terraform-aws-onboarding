locals {
  upwind_version = "TF-4.1.1"

  # An orchestrator is considered configured only when a non-empty account id
  # is supplied. The root module passes null (not "") when unset, so both must
  # be handled.
  has_orchestrator_account = var.orchestrator_account_id != null && var.orchestrator_account_id != ""
}
