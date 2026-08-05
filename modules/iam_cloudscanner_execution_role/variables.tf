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

