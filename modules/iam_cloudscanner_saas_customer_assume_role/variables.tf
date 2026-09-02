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
