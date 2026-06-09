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

variable "cloudscanner_admin_role_name" {
  description = "The name to be used for the CloudScanner admin role."
  type        = string
  default     = null

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
  default     = null

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.cloudscanner_execution_role_name))
    error_message = "The CloudScanner Execution role name contains invalid characters."
  }

  validation {
    condition     = length(var.cloudscanner_execution_role_name) <= 64
    error_message = "The CloudScanner Execution role name is too long."
  }
}

variable "account_service_cloudformation_policy_name" {
  description = "The name to be used for the Cloudformation policy in the account service role."
  type        = string
  default     = null

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.account_service_cloudformation_policy_name))
    error_message = "The Cloudformation policy name contains invalid characters."
  }

  validation {
    condition     = length(var.account_service_cloudformation_policy_name) <= 128
    error_message = "The Cloudformation policy name is too long."
  }
}

variable "account_service_cloudscanner_ec2_policy_name" {
  description = "The name to be used for the CloudScanner EC2 policy in the account service role."
  type        = string
  default     = null

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.account_service_cloudscanner_ec2_policy_name))
    error_message = "The CloudScanner EC2 policy name contains invalid characters."
  }

  validation {
    condition     = length(var.account_service_cloudscanner_ec2_policy_name) <= 128
    error_message = "The CloudScanner EC2 policy name is too long."
  }
}

variable "account_service_cloudscanner_policy_name" {
  description = "The name to be used for the CloudScanner policy in the account service role."
  type        = string
  default     = null

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.account_service_cloudscanner_policy_name))
    error_message = "The CloudScanner policy name contains invalid characters."
  }

  validation {
    condition     = length(var.account_service_cloudscanner_policy_name) <= 128
    error_message = "The CloudScanner policy name is too long."
  }
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

variable "cloudscanner_secret_arn" {
  description = "The ARN of the secret used to store the CloudScanner Auth credentials."
  type        = string
  default     = null

  validation {
    condition     = can(regex("^arn:aws:secretsmanager:[a-z]{2}-[a-z]+-\\d:[0-9]{12}:secret:[a-zA-Z0-9_./-]+-[a-zA-Z0-9]+$", var.cloudscanner_secret_arn)) || var.cloudscanner_secret_arn == null
    error_message = "The CloudScanner secret ARN must be a valid AWS Secrets Manager ARN."
  }
}

variable "apply_for_orchestrator_account" {
  description = "Create the additional roles for the orchestrator account."
  type        = bool
  default     = false
}

#######################################################################################
# The following variables are used conditionally enable / disable feature options
#######################################################################################
variable "upwind_feature_dspm_enabled" {
  description = "Enable the creation of roles to enable DSPM scanning. This includes permissions to access the the contents of S3 buckets."
  type        = bool
}

variable "upwind_cloudscanner_management_enabled" {
  description = "Enable the permissions necessary to support automated CloudScanner deployment and management."
  type        = bool
  default     = true
}

variable "upwind_include_ec2_network_management_permissions" {
  description = "Include permissions necessary to create and manage EC2 network resources"
  type        = bool
  default     = true
}

variable "upwind_agentless_k8s_access_entries_enabled" {
  description = "Enable the creation of the policy for agentless Kubernetes resource fetching using EKS access entries as the authentication method."
  type        = bool
  default     = false
}

variable "upwind_agentless_k8s_ssm_enabled" {
  description = "Enable the creation of the policy for agentless Kubernetes resource fetching from private EKS clusters via SSM tunnels."
  type        = bool
  default     = false
}

variable "upwind_agentless_k8s_eks_admin_view_policy_enabled" {
  description = "Allow the role to associate AmazonEKSAdminViewPolicy (in addition to AmazonEKSViewPolicy) on Upwind-created access entries. Only takes effect when upwind_agentless_k8s_access_entries_enabled is true."
  type        = bool
  default     = true
}

variable "upwind_agentless_k8s_account_whitelist" {
  description = "(Optional). If set, limits the accounts in which the agentless Kubernetes permissions are created."
  type        = list(string)
  default     = []
}

variable "current_account_id" {
  description = "(Optional). Explicit account ID. Provide this when using upwind_agentless_k8s_account_whitelist so Terraform can determine resource creation during plan."
  type        = string
  default     = null

  validation {
    condition     = var.current_account_id == null || can(regex("^[0-9]{12}$", var.current_account_id))
    error_message = "current_account_id must be a 12-digit AWS account ID."
  }
}

variable "account_service_agentless_k8s_access_entries_policy_name" {
  description = "The name to be used for the agentless Kubernetes access entries policy in the account service role."
  type        = string
  default     = "UpwindAccountServiceAgentlessK8sAEPolicy"

  validation {
    condition     = can(regex("^[\\w+=,.@-]+$", var.account_service_agentless_k8s_access_entries_policy_name))
    error_message = "The agentless Kubernetes access entries policy name contains invalid characters."
  }

  validation {
    condition     = length(var.account_service_agentless_k8s_access_entries_policy_name) <= 128
    error_message = "The agentless Kubernetes access entries policy name is too long."
  }
}

variable "account_service_agentless_k8s_ssm_policy_name" {
  description = "The name to be used for the agentless Kubernetes SSM policy in the account service role."
  type        = string
  default     = "UpwindAccountServiceAgentlessK8sSSMPolicy"

  validation {
    condition     = can(regex("^[\\w+=,.@-]+$", var.account_service_agentless_k8s_ssm_policy_name))
    error_message = "The agentless Kubernetes SSM policy name contains invalid characters."
  }

  validation {
    condition     = length(var.account_service_agentless_k8s_ssm_policy_name) <= 128
    error_message = "The agentless Kubernetes SSM policy name is too long."
  }
}

variable "custom_tags" {
  description = "Custom tags which shall be applied to each resource created by the module."
  type        = map(string)
  default     = {}
}

variable "is_saas_mode" {
  description = "Whether this is a SaaS deployment. Used to set discovery tags on the account service role."
  type        = bool
  default     = false
}

variable "cloudscanner_saas_customer_assume_role_name" {
  description = "Name of the SaaS customer assume role. When set, added as a discovery tag on the account service role."
  type        = string
  default     = null
}
