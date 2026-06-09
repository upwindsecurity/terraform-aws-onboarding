output "organization_discovery_role_arn" {
  description = "The ARN of the IAM role created for account discovery purposes. This ARN should be entered in to the Upwind Console"
  value       = one(module.org_discovery_role[*].iam_role.arn)
}

output "organization_discovery_role_name" {
  description = "The Name of the IAM role created for account discovery purposes."
  value       = one(module.org_discovery_role[*].iam_role.name)
}
output "account_service_role_arn" {
  description = "The ARN of the IAM role created for security auditing purposes."
  value       = one(module.account_service_role[*].iam_role.arn)
}

output "account_service_role_name" {
  description = "The Name of the IAM role created for security auditing purposes."
  value       = one(module.account_service_role[*].iam_role.name)
}

output "cloudscanner_admin_role_arn" {
  description = "The ARN of the CloudScanner admin IAM role created for managing cloud scanning operations."
  value       = one(module.cloudscanner_admin_role[*].iam_role.arn)
}

output "cloudscanner_admin_role_name" {
  description = "The Name of the CloudScanner admin IAM role created for managing cloud scanning operations."
  value       = one(module.cloudscanner_admin_role[*].iam_role.name)
}

output "cloudscanner_secret_arn" {
  description = "The ARN of the CloudScanner Credentials secret."
  value       = one(module.cloudscanner_secret[*].secret.arn)
}

output "cloudscanner_secret_name" {
  description = "The name of the CloudScanner Credentials secret."
  value       = one(module.cloudscanner_secret[*].secret.name)
}

output "cloudscanner_execution_role_arn" {
  description = "The ARN of the CloudScanner execution IAM role created for performing cloud scanning operations."
  value       = one(module.cloudscanner_execution_role[*].iam_role.arn)
}

output "cloudscanner_execution_role_name" {
  description = "The Name of the CloudScanner execution IAM role created for performing cloud scanning operations."
  value       = one(module.cloudscanner_execution_role[*].iam_role.name)
}

output "upwind_release_version" {
  description = "The release version tag assigned to the deployment. For version visibility."
  value       = local.upwind_version
}
output "org_registration_response" {
  description = "Org role registration response"
  value       = one(module.register_org_discovery_role[*])
}

output "org_registration_response_state" {
  description = "Org role registration response state"
  value       = one(module.register_org_discovery_role[*].org_role_register_state)
}


