output "account_service_role_arn" {
  description = "The ARN of the IAM role created for security auditing purposes."
  value       = module.upwind_virtual_org_account_onboarding.account_service_role_arn
}

output "account_service_role_name" {
  description = "The Name of the IAM role created for security auditing purposes."
  value       = module.upwind_virtual_org_account_onboarding.account_service_role_name
}

output "cloudscanner_secret_arn" {
  description = "The ARN of the credentials secret created by the module (null when an existing secret ARN is provided)."
  value       = module.upwind_virtual_org_account_onboarding.cloudscanner_secret_arn
}

output "upwind_release_version" {
  description = "The release version tag assigned to the deployment. For version visibility."
  value       = module.upwind_virtual_org_account_onboarding.upwind_release_version
}
