variable "upwind_trusted_account_id" {
  # For the majority of use cases this should be left as the default.
  description = "The identifier of the trusted account used for IAM cross-account access."
  type        = string
  default     = "340457201789"
  validation {
    condition     = can(regex("^[0-9]{12}$", var.upwind_trusted_account_id))
    error_message = "The value for the Upwind trusted account id must be a 12-digit AWS account ID."
  }
}

variable "external_id" {
  # The external_id is attached to the trusted entities allowing assume-role requests from upwind to be authenticated.
  description = "The external ID for secure cross-account role assumption."
  type        = string
}

variable "orchestrator_account_id" {
  # Additional permissions will be created in the orchestrator account - allowing CloudScanners to be installed. If provided additional roles will also be provided
  # in this account.
  description = "The account ID of the Upwind orchestrator account. If specified, certain roles will only be created in this account to maintain operational security and control."
  type        = string
  default     = null

  # If the orchestrator account id role is set it must be a valid account id
  validation {
    condition     = can(regex("^[0-9]{12}$", var.orchestrator_account_id)) || var.orchestrator_account_id == null
    error_message = "The value for the orchestrator account id must be a 12-digit AWS account ID or an empty string."
  }
}

variable "management_account_id" {
  # The Organization discovery role will be created in the management account.
  description = "The account ID of the AWS Organization management account. The Org discover role will be created in this account."
  type        = string

  # If the orchestrator account id role is set it must be a valid account id
  validation {
    condition     = can(regex("^[0-9]{12}$", var.management_account_id))
    error_message = "The value for the AWS management account must be a 12-digit AWS account ID or an empty string."
  }
}

variable "install_roles_in_management_account" {
  # Enabling this option will install additional roles in the management account which allows that account to be scanned if required.
  # It would also allow the management account to be used as the orchestrator account if the same account is selected.
  description = "Install the additional roles in the management account - if required."
  type        = bool
  default     = false
}

variable "organization_role_name" {
  description = "The base name of the IAM role to be created, used for account discovery within the AWS Org."
  type        = string
  default     = "UpwindOrganizationServiceRole"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.organization_role_name))
    error_message = "The base Org discovery role name contains invalid characters."
  }

  # Full Role name validation is delegated to the sub modules.
}

variable "account_service_role_name" {
  description = "The base name of the IAM role to be created, used for security auditing purposes."
  type        = string
  default     = "UpwindAccountServiceRole"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.account_service_role_name))
    error_message = "The base Account service role name contains invalid characters."
  }

  # Full role name validation is delegated to the sub modules.
}

variable "account_service_cloudformation_policy_name" {
  description = "The base name to be used for the Cloudformation policy name in the account service role."
  type        = string
  default     = "UpwindAccountServiceCloudFormationPolicy"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.account_service_cloudformation_policy_name))
    error_message = "The Cloudformation policy base name contains invalid characters."
  }

  # Full policy name validation is delegated to the sub modules.
}

variable "account_service_cloudscanner_ec2_policy_name" {
  description = "The base name to be used for the CloudScanner EC2 policy name in the account service role."
  type        = string
  default     = "UpwindAccountServiceCloudScannerEC2Policy"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.account_service_cloudscanner_ec2_policy_name))
    error_message = "The CloudScanner EC2 policy base name contains invalid characters."
  }
  # Full policy name validation is delegated to the sub modules.
}

variable "account_service_cloudscanner_policy_name" {
  description = "The base name to be used for the CloudScanner policy name in the account service role."
  type        = string
  default     = "UpwindAccountServiceCloudScannerPolicy"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.account_service_cloudscanner_policy_name))
    error_message = "The CloudScanner policy base name contains invalid characters."
  }

  # Full policy name validation is delegated to the sub modules.
}

variable "account_service_cloudscanner_ec2_network_policy_name" {
  description = <<EOT
The base name to be used when creating the CloudScanner EC2 Network Policy for the Account Service role.
This policy contains permissions to create and manage EC2 network resources which can be omitted if you
intend to provide the network stack configuration.
  EOT
  type        = string
  default     = "UpwindAccountServiceCloudScannerEC2NetworkPolicy"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.account_service_cloudscanner_ec2_network_policy_name))
    error_message = "The CloudScanner EC2 network policy base name contains invalid characters."
  }

  # Full policy name validation is delegated to the sub modules.
}

variable "cloudscanner_administration_role_name" {
  description = "The base name of the IAM administration role to be created, used for cloud scanning operations."
  type        = string
  default     = "UpwindCloudScannerAdministrationRole"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.cloudscanner_administration_role_name))
    error_message = "The base CloudScanner admin role name contains invalid characters."
  }

  # Full role name validation is delegated to the sub modules.
}

variable "cloudscanner_execution_role_name" {
  description = "The base name of the IAM execution role to be created, used for cloud scanning operations."
  type        = string
  default     = "UpwindCloudScannerExecutionRole"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.cloudscanner_execution_role_name))
    error_message = "The base CloudScanner execution role name contains invalid characters."
  }

  # Full Role name validation is delegated to the sub modules.
}

variable "upwind_cloudscanner_auth_client_id" {
  # The upwind_cloudscanner_auth_client_id and upwind_cloudscanner_auth_secret_value are used by the CloudScanner to make authenticated requests to the Upwind SaaS. If provided they will
  # be stored in a secret. Otherwise a secret ARN should be provided using upwind_cloudscanner_auth_secret_arn.
  description = "The CloudScanner client ID for Upwind Security authentication."
  type        = string
  sensitive   = true
  default     = null
}

variable "upwind_cloudscanner_auth_secret_value" {
  description = "The CloudScanner client secret for Upwind Security authentication."
  type        = string
  sensitive   = true
  default     = null
}

variable "upwind_cloudscanner_auth_secret_arn" {
  description = "The ARN of the secret containing the CloudScanner credentials."
  type        = string
  default     = null
  validation {
    condition     = can(regex("^arn:aws:secretsmanager:[a-z]{2}-[a-z]+-\\d:[0-9]{12}:secret:[a-zA-Z0-9_./-]+-[a-zA-Z0-9]+$", var.upwind_cloudscanner_auth_secret_arn)) || var.upwind_cloudscanner_auth_secret_arn == null
    error_message = "The secret ARN must be a valid AWS Secrets Manager ARN."
  }
}

variable "credentials_secret_name_prefix" {
  description = "The prefix for the AWS Secrets Manager secret name storing Upwind client credentials. Used to create the secret if `UpwindClientId` and `UpwindClientSecret` are provided."
  type        = string
  default     = "/upwind"
}

variable "cloudscanner_secret_name" {
  description = "The base name used when creating the CloudScanner credentials secret."
  type        = string
  default     = "/cloudscanner-credentials"
}

variable "role_name_suffix" {
  # The role name suffix shall be appended to role names to ensure they are unique for different installations.
  description = "A user specific suffix that will be appended to resources - eg role names."
  type        = string
  default     = null

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.role_name_suffix)) || var.role_name_suffix == null
    error_message = "The suffix must contain only alpha numerical characters, if provided."
  }

  # The suffix will be appended to specific resource names - if provided, thus creating unique resource names.
  # These will be fully validated by the sub modules.
}

#######################################################################################
# The following variables are used conditionally enable / disable feature options
#######################################################################################
variable "upwind_feature_dspm_enabled" {
  description = "Enable the creation of roles to enable DSPM scanning. This includes permissions to access the the contents of S3 buckets."
  type        = bool
  default     = true
}

variable "upwind_feature_dspm_account_whitelist" {
  description = "(Optional). If set, and given upwind_feature_dspm_enabled is true, this will limit the accounts that we create the DSPM S3 permissions in"
  type        = list(string)
  default     = []
}

variable "upwind_cloudscanner_management_enabled" {
  description = "Enable the permissions necessary to support automated CloudScanner deployment and management."
  type        = bool
  default     = true
}

variable "upwind_include_ec2_network_management_permissions" {
  description = "Include permissions necessary to create and manage EC2 network resources."
  type        = bool
  default     = true
}

variable "custom_tags" {
  description = "Custom tags which shall be applied to each resource created by the module."
  type        = map(string)
  default     = {}
}


#######################################################################################
# The following variables are used as part of the Org Discovery role registration
#######################################################################################
variable "upwind_disable_org_discovery_role_registration" {
  description = "Disable the Org discovery role registration process."
  type        = bool
  default     = false
}

variable "upwind_organization_id" {
  description = "The identifier of the Upwind organization to integrate with."
  type        = string
  default     = null
}

variable "upwind_region" {
  type        = string
  description = "Which Upwind region to communicate with. 'us', 'eu' or 'me', or custom region."
  default     = "us"
}

variable "upwind_org_register_auth_client_id" {
  description = "The client ID used for authentication with the Upwind Authorization Service."
  type        = string
  default     = null
}

variable "upwind_org_register_auth_secret_value" {
  description = "The client secret for authentication with the Upwind Authorization Service."
  type        = string
  default     = null
}

variable "upwind_org_register_auth_secret_arn" {
  description = "The ARN of a secret containing the org registration secret."
  type        = string
  default     = null
}

variable "upwind_auth_endpoint" {
  description = "The Authentication API endpoint."
  type        = string
  default     = "https://auth.upwind.io"
}

variable "upwind_integration_endpoint" {
  description = "The Integration API endpoint."
  type        = string
  default     = "https://integration.upwind.io"
}

variable "aws_iam_role_creation_wait_time" {
  description = "The duration of time to wait for the completion of the IAM role creation."
  type        = string
  default     = "20s"
}
