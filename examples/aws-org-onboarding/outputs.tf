output "organization_discovery_role_arn" {
  description = "The ARN of the IAM role created for account discovery purposes. This ARN should be entered in to the Upwind Console."
  value       = module.upwind_org_account_onboarding.organization_discovery_role_arn
}

output "organization_discovery_role_name" {
  description = "The Name of the IAM role created for account discovery purposes."
  value       = module.upwind_org_account_onboarding.organization_discovery_role_name
}

output "account_service_role_arn" {
  description = "The ARN of the IAM role created for security auditing purposes."
  value       = module.upwind_org_account_onboarding.account_service_role_arn
}

output "account_service_role_name" {
  description = "The Name of the IAM role created for security auditing purposes."
  value       = module.upwind_org_account_onboarding.account_service_role_name
}

output "cloudscanner_administration_role_arn" {
  description = "The ARN of the IAM administration role created for managing cloud scanning operations."
  value       = module.upwind_org_account_onboarding.cloudscanner_admin_role_arn
}

output "cloudscanner_administration_role_name" {
  description = "The Name of the IAM administration role created for managing cloud scanning operations."
  value       = module.upwind_org_account_onboarding.cloudscanner_admin_role_name
}

output "cloudscanner_secret_arn" {
  description = "The ARN of the CloudScanner credentials secret."
  value       = module.upwind_org_account_onboarding.cloudscanner_secret_arn
}

output "cloudscanner_secret_name" {
  description = "The name of the CloudScanner credentials secret."
  value       = module.upwind_org_account_onboarding.cloudscanner_secret_name
}

output "cloudscanner_execution_role_arn" {
  description = "The ARN of the IAM execution role created for performing cloud scanning operations."
  value       = module.upwind_org_account_onboarding.cloudscanner_execution_role_arn
}

output "cloudscanner_execution_role_name" {
  description = "The Name of the IAM execution role created for performing cloud scanning operations."
  value       = module.upwind_org_account_onboarding.cloudscanner_execution_role_name
}

output "upwind_release_version" {
  description = "The release version tag assigned to the deployment. For version visibility."
  value       = module.upwind_org_account_onboarding.upwind_release_version
}
