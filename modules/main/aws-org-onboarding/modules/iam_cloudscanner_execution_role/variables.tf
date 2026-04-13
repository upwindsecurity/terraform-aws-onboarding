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

