variable "trusted_arn" {
  description = "The ARN of the upwind account to be used in the trusted entity of the role."
  type        = string
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

variable "cloudscanner_execution_role_name" {
  description = "The name to be used for the CloudScanner execution role."
  type        = string
  default     = null

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.cloudscanner_execution_role_name)) || var.cloudscanner_execution_role_name == null
    error_message = "The CloudScanner Execution role name contains invalid characters."
  }

  validation {
    condition     = length(var.cloudscanner_execution_role_name) <= 64
    error_message = "The CloudScanner Execution role name is too long."
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
variable "upwind_feature_dspm_enabled" {
  description = "Enable the creation of roles to enable DSPM scanning. This includes permissions to access the the contents of S3 buckets."
  type        = bool
}

variable "upwind_feature_dspm_rds_enabled" {
  description = "Enable DSPM scanning of RDS databases. This includes the permissions required to snapshot and restore RDS databases so their contents can be scanned."
  type        = bool
}

variable "upwind_cloudscanner_management_enabled" {
  description = "Whether CloudScanner management permissions are enabled. Sets the upwind:aws:HasCSAutomationPermissions discovery tag."
  type        = bool
  default     = true
}

variable "is_saas_mode" {
  description = "Whether this is a SaaS deployment. Sets the upwind:aws:CloudScannerSaaSMode discovery tag."
  type        = bool
  default     = false
}

variable "cloudscanner_saas_customer_assume_role_name" {
  description = "Name of the SaaS customer assume role. When set, added as upwind:aws:CustomerAssumeRoleName discovery tag."
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
