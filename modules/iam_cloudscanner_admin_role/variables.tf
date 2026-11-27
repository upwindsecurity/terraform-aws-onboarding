variable "upwind_dev_environment" {
  description = "Use the Upwind dev environment's values for the partition instead of production."
  type        = bool
  default     = false
}

variable "cloudscanner_admin_role_name" {
  description = "The name to be used for the CloudScanner admin role."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.cloudscanner_admin_role_name))
    error_message = "The CloudScanner Admin role name contains invalid characters."
  }

  validation {
    condition     = length(var.cloudscanner_admin_role_name) <= 64
    error_message = "The CloudScanner Admin role name is too long."
  }
}

variable "cloudscanner_admin_role_profile_name" {
  description = "The name to be used for the CloudScanner admin role instance profile."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.cloudscanner_admin_role_profile_name))
    error_message = "The CloudScanner Admin role instance profile name contains invalid characters."
  }

  validation {
    condition     = length(var.cloudscanner_admin_role_profile_name) <= 128
    error_message = "The CloudScanner Admin role instance profile name is too long."
  }
}

variable "cloudscanner_execution_role_name" {
  description = "The name to be used for the CloudScanner execution role."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.cloudscanner_execution_role_name))
    error_message = "The CloudScanner Execution role name contains invalid characters."
  }

  validation {
    condition     = length(var.cloudscanner_execution_role_name) <= 64
    error_message = "The CloudScanner Execution role name is too long."
  }
}

variable "cloudscanner_secret_arn" {
  description = "The ARN of the secret used to store the CloudScanner Auth credentials."
  type        = string

  validation {
    # wildcard following '^arn:' accounts for use of AWS partitions
    condition     = can(regex("^arn:.+:secretsmanager:[a-z]{2}-[a-z]+-\\d:[0-9]{12}:secret:[a-zA-Z0-9_./-]+-[a-zA-Z0-9]+$", var.cloudscanner_secret_arn))
    error_message = "The CloudScanner secret ARN must be a valid AWS Secrets Manager ARN."
  }
}

variable "custom_tags" {
  description = "Custom tags which shall be applied to each resource created by the module."
  type        = map(string)
  default     = {}
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
  description = "The common IAM path applied to the role and instance profile created by this module. Must begin and end with a forward slash (/). Defaults to \"/\" (the AWS default)."
  type        = string
  default     = "/"
}

variable "create_cloudscanner_secret" {
  # false (grant exactly cloudscanner_secret_arn) is correct for any secret; true grants the default name pattern.
  description = "Whether the CloudScanner secret is the one created by this deployment (named <credentials_secret_name_prefix>/cloudscanner-credentials[-<role_name_suffix>]), rather than an existing secret given by ARN."
  type        = bool
  default     = false
  nullable    = false
}

variable "credentials_secret_name_prefix" {
  description = "The name prefix of the CloudScanner secret created by this deployment."
  type        = string
  default     = "/upwind"
  nullable    = false
}

variable "role_name_suffix" {
  description = "The role name suffix (without the leading '-'). Empty when none is used."
  type        = string
  default     = ""
  nullable    = false
}

variable "orchestrator_account_id" {
  description = "The default orchestrator account ID, whose CloudScanner admin role the scaler may pass. Defaults to this account."
  type        = string
  default     = null

  validation {
    condition     = var.orchestrator_account_id == null || can(regex("^[0-9]{12}$", var.orchestrator_account_id))
    error_message = "The orchestrator account id must be a 12-digit AWS account ID."
  }
}

variable "dspm_rds_enabled" {
  description = "Whether DSPM RDS scanning is enabled in this account (adds the executor's VPC ENI permissions)."
  type        = bool
  default     = false
}
