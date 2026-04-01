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
    condition     = can(regex("^arn:aws:secretsmanager:[a-z]{2}-[a-z]+-\\d:[0-9]{12}:secret:[a-zA-Z0-9_./-]+-[a-zA-Z0-9]+$", var.cloudscanner_secret_arn))
    error_message = "The CloudScanner secret ARN must be a valid AWS Secrets Manager ARN."
  }

}

variable "custom_tags" {
  description = "Custom tags which shall be applied to each resource created by the module."
  type        = map(string)
  default     = {}
}
