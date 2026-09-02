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
