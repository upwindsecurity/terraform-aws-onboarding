variable "role_name" {
  description = "The name of the CloudScanner SaaS customer assume role."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.role_name))
    error_message = "The role name contains invalid characters."
  }

  validation {
    condition     = length(var.role_name) <= 64
    error_message = "The role name is too long (max 64 characters)."
  }
}

variable "saas_trusted_account_id" {
  description = "The AWS account ID of the Upwind SaaS account that will assume this role."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.saas_trusted_account_id))
    error_message = "saas_trusted_account_id must be a 12-digit AWS account ID."
  }
}

variable "external_id" {
  description = "The external ID for secure cross-account role assumption."
  type        = string

  validation {
    condition     = can(regexall("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.external_id))
    error_message = "The external id must be a valid UUID."
  }
}

variable "cloudscanner_execution_role_name" {
  description = "The name of the CloudScanner execution role that this role is permitted to assume."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.cloudscanner_execution_role_name))
    error_message = "The execution role name contains invalid characters."
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
