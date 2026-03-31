output "organization_discovery_role_arn" {
  description = "The ARN of the IAM role created for account discovery purposes. This ARN should be entered in to the Upwind Console"
  value       = one(module.upwind_org_account_onboarding.organization_discovery_role_arn[*])
}

output "organization_service_role_name" {
  description = "The Name of the IAM role created for account discovery purposes."
  value       = one(module.upwind_org_account_onboarding.organization_discovery_role_name[*])
}

output "account_service_role_arn" {
  description = "The ARN of the IAM role created for security auditing purposes."
  value       = one(module.upwind_org_account_onboarding.account_service_role_arn[*])
}

output "account_service_role_name" {
  description = "The Name of the IAM role created for security auditing purposes."
  value       = one(module.upwind_org_account_onboarding.account_service_role_name[*])
}

output "cloudscanner_administration_role_arn" {
  description = "The ARN of the IAM administration role created for managing cloud scanning operations."
  value       = one(module.upwind_org_account_onboarding.cloudscanner_admin_role_arn[*])
}

output "cloudscanner_administration_role_name" {
  description = "The Name of the IAM administration role created for managing cloud scanning operations."
  value       = one(module.upwind_org_account_onboarding.cloudscanner_admin_role_name[*])
}

output "cloudscanner_secret_arn" {
  description = "The ARN of the Credentials secret."
  value       = one(module.upwind_org_account_onboarding.cloudscanner_secret_arn[*])
}

output "cloudscanner_secret_name" {
  description = "The Name of the IAM administration role created for managing cloud scanning operations."
  value       = one(module.upwind_org_account_onboarding.cloudscanner_secret_name[*])
}

output "cloudscanner_execution_role_arn" {
  description = "The ARN of the IAM execution role created for performing cloud scanning operations."
  value       = one(module.upwind_org_account_onboarding.cloudscanner_execution_role_arn[*])
}

output "cloudscanner_execution_role_name" {
  description = "The Name of the IAM execution role created for performing cloud scanning operations."
  value       = one(module.upwind_org_account_onboarding.cloudscanner_execution_role_name[*])
}

output "upwind_release_version" {
  description = "The release version tag assgined to the deployment. For version visibility."
  value       = one(module.upwind_org_account_onboarding.upwind_release_version[*])
}

output "org_registration_response" {
  description = "Org registration (full) response."
  value       = one(module.upwind_org_account_onboarding[*])
}

output "org_registration_state" {
  description = "Discovery role registration state."
  value       = one(module.upwind_org_account_onboarding[*].org_registration_response_state)
}

