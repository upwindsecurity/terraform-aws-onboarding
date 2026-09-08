variable "orchestrator_account_id" {
  description = "The orchestrator account id"
  type        = string
  default     = ""
}

variable "cloudscanner_admin_role_name" {
  description = "The name to be used for the CloudScanner admin role."
  type        = string
  default     = ""
}

variable "cloudscanner_execution_role_name" {
  description = "The name to be used for the CloudScanner execution role."
  type        = string
  default     = ""
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

variable "upwind_feature_dspm_account_whitelist" {
  description = "(Optional). If set, and given upwind_feature_dspm_enabled is true, this will limit the accounts that we create the DSPM S3 permissions in"
  type        = list(string)
  default     = []
}

variable "upwind_feature_dspm_rds_enabled" {
  description = "Enable DSPM scanning of RDS databases. This includes the permissions required to snapshot and restore RDS databases so their contents can be scanned."
  type        = bool
}

variable "upwind_feature_dspm_rds_account_allowlist" {
  description = "(Optional). If set, and given upwind_feature_dspm_rds_enabled is true, this limits the accounts that we create the DSPM RDS permissions in."
  type        = list(string)
  default     = []
}

variable "is_saas_mode" {
  description = "Whether this is a SaaS deployment. When true, the execution role's trust policy trusts the customer assume role instead of the admin role."
  type        = bool
  default     = false
}

variable "cloudscanner_saas_customer_assume_role_name" {
  description = "Name of the SaaS customer assume role. Used in the execution role trust policy when is_saas_mode = true."
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

