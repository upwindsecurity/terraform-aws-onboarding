variable "trusted_account_id" {
  description = "The Upwind account trusted to assume the role."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.trusted_account_id))
    error_message = "trusted_account_id must be a 12-digit AWS account ID."
  }
}

variable "external_id" {
  description = "The external ID for secure cross-account role assumption."
  type        = string

  validation {
    condition     = can(regexall("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.external_id))
    error_message = "The external id is not of the correct format."
  }
}

variable "org_discovery_role_name" {
  description = "The name to be given to the Org Discovery role."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.org_discovery_role_name))
    error_message = "The Org discovery role name contains invalid characters."
  }

  validation {
    condition     = length(var.org_discovery_role_name) <= 64
    error_message = "The Org discovery role name is too long."
  }
}

variable "account_service_role_name" {
  description = "The name to be used for the Account Service role."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.account_service_role_name))
    error_message = "The Account Service role name contains invalid characters."
  }

  validation {
    condition     = length(var.account_service_role_name) <= 64
    error_message = "The Account Service role name is too long."
  }
}

variable "orchestrator_account_id" {
  description = "The orchestrator account id"
  type        = string
  default     = null
}

variable "cloudscanner_admin_role_name" {
  description = "The name to be used for the CloudScanner admin role."
  type        = string
  default     = null

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.cloudscanner_admin_role_name)) || var.cloudscanner_admin_role_name == null
    error_message = "The Account Service role name contains invalid characters."
  }

  validation {
    condition     = length(var.cloudscanner_admin_role_name) <= 64
    error_message = "The Account Service role name is too long."
  }
}

variable "custom_tags" {
  description = "Custom tags which shall be applied to each resource created by the module."
  type        = map(string)
  default     = {}
}

#######################################################################################
# The following variables are used conditionally enable / disable feature options
#######################################################################################
variable "is_saas_mode" {
  description = "Whether this is a SaaS deployment. Sets the upwind:aws:CloudScannerSaaSMode discovery tag, and selects the upwind:aws:CustomerAssumeRoleName tag over upwind:aws:CloudScannerAdministrationRoleName."
  type        = bool
  default     = false
}

variable "cloudscanner_saas_customer_assume_role_name" {
  description = "Name of the SaaS customer assume role (including any suffix). In SaaS mode with an orchestrator account, recorded with the IAM path in the upwind:aws:CustomerAssumeRoleName discovery tag."
  type        = string
  default     = null
}

variable "permissions_boundary" {
  description = <<EOT
(Optional). A pre-existing IAM permissions boundary policy to attach to the role. It constrains the maximum
permissions the role can have and grants nothing itself - the policy must already exist in this account.
Provide either the full policy ARN (e.g. arn:aws:iam::123456789012:policy/MyBoundary) or just the policy name
including any path but WITHOUT a leading slash (e.g. MyBoundary or team/security/MyBoundary), in which case the
ARN is formed for this account. Leave null to create the role without a permissions boundary.
  EOT
  type        = string
  default     = null
}

variable "iam_role_path" {
  description = "The common IAM path applied to the role created by this module. Must begin and end with a forward slash (/). Defaults to \"/\" (the AWS default)."
  type        = string
  default     = "/"
}

variable "additional_orchestrator_account_ids" {
  description = "Additional orchestrator account IDs. Appended, ':'-separated, to the default orchestrator account in the upwind:aws:OrchestratorAccountId discovery tag."
  type        = list(string)
  default     = []
}

variable "ssm_parameter_prefix" {
  description = "The SSM Parameter Store path prefix of the onboarding settings in the orchestrator account (including any role name suffix segment). Recorded in the upwind:aws:SSMParameterPrefix discovery tag. This should not normally be changed."
  type        = string
  default     = "/upwind/onboarding/configuration"
}
