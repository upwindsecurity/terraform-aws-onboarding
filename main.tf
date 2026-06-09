module "upwind_aws_org_onboarding" {
  source = "./modules/main/aws-org-onboarding"

  # ---------------------------------------
  # Core Upwind endpoints
  # ---------------------------------------
  upwind_auth_endpoint        = var.upwind_auth_endpoint
  upwind_integration_endpoint = var.upwind_integration_endpoint

  # ---------------------------------------
  # Organization identity
  # ---------------------------------------
  upwind_organization_id     = var.upwind_organization_id
  upwind_trusted_account_id  = var.upwind_trusted_account_id

  # ---------------------------------------
  # AWS account / org structure
  # ---------------------------------------
  orchestrator_account_id   = var.orchestrator_account_id
  management_account_id     = var.management_account_id

  # ---------------------------------------
  # Role configuration
  # ---------------------------------------
  role_name_suffix                    = var.role_name_suffix
  external_id                         = var.external_id
  install_roles_in_management_account = var.install_roles_in_management_account

  # ---------------------------------------
  # Auth registration (org onboarding)
  # ---------------------------------------
  upwind_org_register_auth_client_id    = var.upwind_org_register_auth_client_id
  upwind_org_register_auth_secret_value = var.upwind_org_register_auth_secret_value

  # ---------------------------------------
  # CloudScanner credentials
  # ---------------------------------------
  upwind_cloudscanner_auth_client_id    = var.upwind_cloudscanner_auth_client_id
  upwind_cloudscanner_auth_secret_value = var.upwind_cloudscanner_auth_secret_value

  # ---------------------------------------
  # Permissions toggles
  # ---------------------------------------
  upwind_include_ec2_network_management_permissions = var.upwind_include_ec2_network_management_permissions
}