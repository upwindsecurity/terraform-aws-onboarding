variable "upwind_dev_environment" {
  # For the majority of use cases this should be left as the default.
  description = "Deploy for the Upwind dev environment: the trusted account and template buckets default to the dev environment's for the AWS partition being deployed to, instead of production."
  type        = bool
  default     = false
}

variable "upwind_trusted_account_id" {
  # For the majority of use cases this should be left as the default.
  description = "The account id to be configured as the trusted principal: the account Upwind will assume the roles from. Defaults to Upwind's account for the AWS partition (and environment, see upwind_dev_environment) being deployed to."
  type        = string
  default     = null
  validation {
    condition     = var.upwind_trusted_account_id == null || can(regex("^[0-9]{12}$", var.upwind_trusted_account_id))
    error_message = "The value for the Upwind trusted account id must be a 12-digit AWS account ID."
  }
}

variable "upwind_cfn_bucket" {
  # For the majority of use cases this should be left as the default; for the Upwind dev
  # environment set upwind_dev_environment instead.
  description = "Optional. The Upwind S3 bucket hosting the CloudFormation templates the account service role policies allow. Defaults to Upwind's bucket for the AWS partition (and environment, see upwind_dev_environment) being deployed to."
  type        = string
  default     = null

  validation {
    condition     = var.upwind_cfn_bucket == null || length(var.upwind_cfn_bucket) > 0
    error_message = "The Upwind CloudFormation bucket host must not be empty."
  }
}

variable "external_id" {
  # The external_id is attached to the trusted entities allowing assume-role requests from upwind to be authenticated.
  description = "The external ID for secure cross-account role assumption. This is included in the trusted identity of each role that can be assumed from the Upwind SaaS."
  type        = string
}

variable "orchestrator_account_id" {
  # Additional permissions will be created in the orchestrator account - allowing CloudScanners to be installed. If provided additional roles will also be provided
  # in this account.
  description = "The account ID of the default Upwind orchestrator account. The orchestrator account is considered a \"special\" account where the CloudScanners will be installed and managed. If specified, additional roles and permissions will be created in this account to allow for the installation and management of the CloudScanners."
  type        = string
  default     = null

  # If the orchestrator account id role is set it must be a valid account id
  validation {
    condition     = can(regex("^[0-9]{12}$", var.orchestrator_account_id)) || var.orchestrator_account_id == null
    error_message = "The value for the orchestrator account id must be a 12-digit AWS account ID or an empty string."
  }
}

variable "additional_orchestrator_account_ids" {
  # The orchestrator resources (CloudScanner admin role, secret, onboarding settings) are also created in these
  # accounts, and the CloudScanner execution role in every account trusts their CloudScanner admin role.
  description = "A list of 12-digit account IDs to treat as additional Upwind orchestrator accounts, alongside the default orchestrator account. The CloudScanners are installed and managed in each orchestrator account. The orchestrator resources are deployed to these accounts, the CloudScanner Execution role in every account trusts their CloudScanner Administration role, and the list is recorded in the onboarding settings and in a tag on the Organization (discovery) role so that Upwind can find them. Leave empty to use only the default orchestrator account."
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for id in var.additional_orchestrator_account_ids : can(regex("^[0-9]{12}$", id))])
    error_message = "Each additional orchestrator account id must be a 12-digit AWS account ID."
  }
}

variable "outpost_only_account_ids" {
  # Only relevant in SaaS mode: the customer assume role is denied the CloudScanner execution role in these accounts.
  description = "A list of 12-digit account IDs that must not be scanned using CloudScanner SaaS, because they use an Outpost (customer-hosted) CloudScanner deployment. Only relevant when CloudScanner SaaS is enabled: in these accounts the CloudScanner SaaS Customer Assume role is explicitly denied from assuming the CloudScanner Execution role. The list is also recorded in the onboarding settings. It applies to individual accounts only, not to OUs. Leave empty if no accounts are Outpost-only."
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for id in var.outpost_only_account_ids : can(regex("^[0-9]{12}$", id))])
    error_message = "Each Outpost-only account id must be a 12-digit AWS account ID."
  }
}

variable "management_account_id" {
  # The Organization discovery role will be created in the management account.
  description = "The account ID of the AWS Organization management account. The Org Discovery role will be created in this account."
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
  description = "Controls whether roles, in addition to the Org Discovery role, are created in the management account. If disabled, Upwind is unable to perform audits or scans in the Org Management account."
  type        = bool
  default     = false
}

variable "organization_role_name" {
  description = "The name to be given to the Org Discovery IAM role. The Org Discovery role is created in the management account and grants permissions to discover the Organization account structure."
  type        = string
  default     = "UpwindOrganizationServiceRole"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.organization_role_name))
    error_message = "The base Org discovery role name contains invalid characters."
  }

  # Full Role name validation is delegated to the sub modules.
}

variable "account_service_role_name" {
  description = "The name to be given to the Account Service IAM role. The Account Service role is created in each account to be connected and is generally used for account auditing purposes."
  type        = string
  default     = "UpwindAccountServiceRole"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.account_service_role_name))
    error_message = "The base Account service role name contains invalid characters."
  }

  # Full role name validation is delegated to the sub modules.
}

variable "account_service_cloudformation_policy_name" {
  description = "The base name to be used when creating the CloudFormation Policy for the Account Service role."
  type        = string
  default     = "UpwindAccountServiceCloudFormationPolicy"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.account_service_cloudformation_policy_name))
    error_message = "The Cloudformation policy base name contains invalid characters."
  }

  # Full policy name validation is delegated to the sub modules.
}

variable "account_service_cloudscanner_ec2_policy_name" {
  description = "The base name to be used when creating the CloudScanner EC2 Access Policy for the Account Service role."
  type        = string
  default     = "UpwindAccountServiceCloudScannerEC2Policy"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.account_service_cloudscanner_ec2_policy_name))
    error_message = "The CloudScanner EC2 policy base name contains invalid characters."
  }
  # Full policy name validation is delegated to the sub modules.
}

variable "account_service_cloudscanner_policy_name" {
  description = "The base name to be used when creating the CloudScanner Access Policy for the Account Service role."
  type        = string
  default     = "UpwindAccountServiceCloudScannerPolicy"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.account_service_cloudscanner_policy_name))
    error_message = "The CloudScanner policy base name contains invalid characters."
  }

  # Full policy name validation is delegated to the sub modules.
}

variable "account_service_cloudscanner_ec2_network_policy_name" {
  description = "The base name to be used when creating the CloudScanner EC2 Network Policy for the Account Service role. This policy contains permissions to create and manage EC2 network resources which can be omitted if you intend to provide the network stack configuration."
  type        = string
  default     = "UpwindAccountServiceCloudScannerEC2NetworkPolicy"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.account_service_cloudscanner_ec2_network_policy_name))
    error_message = "The CloudScanner EC2 network policy base name contains invalid characters."
  }

  # Full policy name validation is delegated to the sub modules.
}

variable "account_service_agentless_k8s_access_entries_policy_name" {
  description = "The base name to be used when creating the Agentless Kubernetes Access Entries Policy for the Account Service role."
  type        = string
  default     = "UpwindAccountServiceAgentlessK8sAEPolicy"

  validation {
    condition     = can(regex("^[\\w+=,.@-]+$", var.account_service_agentless_k8s_access_entries_policy_name))
    error_message = "The agentless Kubernetes access entries policy base name contains invalid characters."
  }

  # Full policy name validation is delegated to the sub modules.
}

variable "account_service_agentless_k8s_ssm_policy_name" {
  description = "The base name to be used when creating the Agentless Kubernetes SSM Policy for the Account Service role."
  type        = string
  default     = "UpwindAccountServiceAgentlessK8sSSMPolicy"

  validation {
    condition     = can(regex("^[\\w+=,.@-]+$", var.account_service_agentless_k8s_ssm_policy_name))
    error_message = "The agentless Kubernetes SSM policy base name contains invalid characters."
  }

  # Full policy name validation is delegated to the sub modules.
}

variable "cloudscanner_administration_role_name" {
  description = "The name to be given to the CloudScanner Administration IAM role. This role will only be created in the Orchestrator account if configured, and grants the operational permissions for the CloudScanners to run."
  type        = string
  default     = "UpwindCloudScannerAdministrationRole"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.cloudscanner_administration_role_name))
    error_message = "The base CloudScanner admin role name contains invalid characters."
  }

  # Full role name validation is delegated to the sub modules.
}

variable "cloudscanner_administration_role_profile_name" {
  description = "The name of the EC2 Instance profile that will be associated with the CloudScanner Admin role."
  type        = string
  default     = "UpwindCloudScannerAdministrationRoleProfile"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.cloudscanner_administration_role_profile_name))
    error_message = "The CloudScanner Admin role instance profile name contains invalid characters."
  }

  # Full role name validation is delegated to the sub modules.
}


variable "cloudscanner_execution_role_name" {
  description = "The name to be given to the CloudScanner Execution IAM role. This role will be created in each account onboarded, and grants permissions to allow the CloudScanners to perform cross-account scanning."
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
  description = "An ARN for an existing CloudScanner secret can be specified as an alternative to the client ID and client secret on Outpost deployments. If provided, it will be used instead of creating a secret. This needs to be accessible to the CloudScanners which shall be installed in the orchestrator account. For SaaS deployments, this field should remain empty."
  type        = string
  default     = null
  validation {
    # wildcard following '^arn:' accounts for use of AWS partitions
    condition     = can(regex("^arn:.+:secretsmanager:[a-z]{2}-[a-z]+-\\d:[0-9]{12}:secret:[a-zA-Z0-9_./-]+-[a-zA-Z0-9]+$", var.upwind_cloudscanner_auth_secret_arn)) || var.upwind_cloudscanner_auth_secret_arn == null
    error_message = "The secret ARN must be a valid AWS Secrets Manager ARN."
  }
}

variable "credentials_secret_name_prefix" {
  description = "The prefix for the AWS Secrets Manager secret name storing Upwind client credentials. Used to create the secret if the client ID and client secret are provided."
  type        = string
  default     = "/upwind"
}

variable "cloudscanner_secret_name" {
  description = "The base name used when creating the CloudScanner credentials secret."
  type        = string
  default     = "/cloudscanner-credentials"
}

variable "ssm_parameter_prefix" {
  # The settings parameter is <prefix>/settings1, or <prefix>/<role_name_suffix>/settings1 with a role name suffix.
  description = "The SSM Parameter Store path prefix under which the onboarding settings are stored in the orchestrator accounts. This should not normally be changed."
  type        = string
  default     = "/upwind/onboarding/configuration"

  validation {
    condition     = can(regex("^(/[a-zA-Z0-9_.-]+)+$", var.ssm_parameter_prefix))
    error_message = "The SSM parameter prefix must begin with a forward slash (/), not end with one, and contain only letters, numbers, '_', '.', '-' and '/'."
  }
}

variable "role_name_suffix" {
  # The role name suffix shall be appended to role names to ensure they are unique for different installations.
  description = "A suffix that will be appended to the role names to ensure they are unique."
  type        = string
  default     = null

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.role_name_suffix)) || var.role_name_suffix == null
    error_message = "The suffix must contain only alpha numerical characters, if provided."
  }

  # The suffix will be appended to specific resource names - if provided, thus creating unique resource names.
  # These will be fully validated by the sub modules.
}

variable "iam_role_path" {
  # A single customisable path applied to every IAM role, managed policy and instance profile created
  # during onboarding. It maps straight through to the IAM Path property, so it must begin and end with a
  # forward slash (/) - e.g. "/security/upwind/". Setting a path changes the role ARNs (and the discoverable
  # role names) from arn:...:role/<name> to arn:...:role<path><name>. The default "/" is the AWS default and
  # leaves existing installations unchanged. IMPORTANT: changing this on an existing installation replaces the
  # roles (the path is part of their identity).
  description = "The common IAM Role Path to be used with all IAM role and policies. This maps straight through to the IAM Path property on the IAM roles and policies - i.e. it must begin and end with a forward slash `/` - eg `/security/upwind/`."
  type        = string
  default     = "/"

  validation {
    condition     = var.iam_role_path == "/" || can(regex("^/[\\x21-\\x7F]*/$", var.iam_role_path))
    error_message = "The IAM role path must begin and end with a forward slash (/), e.g. \"/\" or \"/security/upwind/\"."
  }
}

#######################################################################################
# The following variables are used conditionally enable / disable feature options
#######################################################################################
variable "upwind_feature_dspm_enabled" {
  description = "Enable the creation of roles to enable DSPM scanning. This includes permissions to access the contents of S3 buckets."
  type        = bool
  default     = true
}

variable "upwind_feature_dspm_account_whitelist" {
  description = "(Optional). If set, and given upwind_feature_dspm_enabled is true, this will limit the accounts that we create the DSPM S3 permissions in"
  type        = list(string)
  default     = []
}

variable "upwind_feature_dspm_rds_enabled" {
  description = "Enable DSPM scanning of RDS databases. This includes the permissions required to snapshot and restore RDS databases so their contents can be scanned."
  type        = bool
  default     = false
}

variable "upwind_feature_dspm_rds_account_allowlist" {
  description = "(Optional). If set, and given upwind_feature_dspm_rds_enabled is true, this limits the accounts that we create the DSPM RDS permissions in."
  type        = list(string)
  default     = []
}

variable "cloudscanner_dspm_rds_execution_policy_name" {
  description = "The base name to be used when creating the CloudScanner DSPM RDS Policy attached to the CloudScanner Execution role. Must differ from the DSPM RDS Policy name."
  type        = string
  default     = "UpwindCloudScannerDspmRdsExecutionPolicy"

  validation {
    condition     = can(regex("^[\\w+=,.@-]+$", var.cloudscanner_dspm_rds_execution_policy_name))
    error_message = "The DSPM RDS execution policy base name contains invalid characters."
  }
}

variable "cloudscanner_dspm_rds_policy_name" {
  description = "The base name of the DSPM RDS managed policy attached to the CloudScanner admin role. Must differ from cloudscanner_dspm_rds_execution_policy_name."
  type        = string
  default     = "UpwindCloudScannerDspmRdsPolicy"

  validation {
    condition     = can(regex("^[\\w+=,.@-]+$", var.cloudscanner_dspm_rds_policy_name))
    error_message = "The DSPM RDS policy base name contains invalid characters."
  }
}

variable "upwind_cloudscanner_management_enabled" {
  description = "Enable the permissions necessary to support automated CloudScanner deployment and management. If disabled the CloudScanner stacks will need to be installed manually."
  type        = bool
  default     = true
}

variable "upwind_include_ec2_network_management_permissions" {
  description = "Include the permissions necessary to create and manage EC2 network resources. If providing custom networking configuration from the start, this can be omitted. Note: CloudScanners will not be installed until the necessary network configuration has been provided."
  type        = bool
  default     = true
}

variable "custom_tags" {
  description = "Custom tags which shall be applied to each resource created by the module."
  type        = map(string)
  default     = {}
}

#######################################################################################
# The following variables configure Agentless Kubernetes support
#######################################################################################
variable "upwind_agentless_k8s_access_entries_enabled" {
  description = "Enable the creation of the policy for agentless Kubernetes resource fetching using EKS access entries as the authentication method."
  type        = bool
  default     = false
}

variable "current_account_id" {
  description = "(Optional). Explicit account ID for AWS account being configured. Provide this when using upwind_agentless_k8s_account_whitelist so terraform can determine resource creation during plan"
  type        = string
  default     = null

  validation {
    condition     = var.current_account_id == null || can(regex("^[0-9]{12}$", var.current_account_id))
    error_message = "current_account_id must be a 12-digit AWS account ID."
  }
}

variable "upwind_agentless_k8s_account_whitelist" {
  description = "(Optional). If set, this will limit the accounts in which the agentless Kubernetes access entry and SSM permissions are created."
  type        = list(string)
  default     = []
}

variable "upwind_agentless_k8s_ssm_enabled" {
  description = "Enable the creation of the policy for agentless Kubernetes resource fetching from private EKS clusters via SSM tunnels."
  type        = bool
  default     = false
}

variable "upwind_agentless_k8s_eks_admin_view_policy_enabled" {
  description = "Allow the role to associate AmazonEKSAdminViewPolicy (in addition to AmazonEKSViewPolicy) on Upwind-created EKS access entries. Only takes effect when agentless Kubernetes resource fetching using access entries is turned on."
  type        = bool
  default     = true
}


#######################################################################################
# The following variables configure SaaS deployment mode
#######################################################################################
variable "is_saas" {
  description = "Enable CloudScanner SaaS mode, where Upwind runs the CloudScanners. The default orchestrator account then gets the CloudScanner SaaS Customer Assume role, which the Upwind SaaS assumes, instead of the CloudScanner Administration role and credentials secret; additional orchestrator accounts still get the Administration role and secret."
  type        = bool
  default     = false
}

variable "cloudscanner_saas_trusted_account_id" {
  description = "The Upwind SaaS account ID that will be configured as the trust principal for the Customer Assume role. Required when deploying with CloudScanner SaaS."
  type        = string
  default     = null

  validation {
    condition     = var.cloudscanner_saas_trusted_account_id == null || can(regex("^[0-9]{12}$", var.cloudscanner_saas_trusted_account_id))
    error_message = "cloudscanner_saas_trusted_account_id must be a 12-digit AWS account ID."
  }
}

variable "cloudscanner_saas_customer_assume_role_name" {
  description = "The name of the CloudScanner Customer Assume IAM role to be created, used by the Upwind SaaS to assume roles in the Customer orchestrator account."
  type        = string
  default     = "UpwindCloudScannerCustomerAssumeRole"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.cloudscanner_saas_customer_assume_role_name))
    error_message = "cloudscanner_saas_customer_assume_role_name contains invalid characters."
  }
}

#######################################################################################
# Permissions boundaries (optional).
#
# Each role created during onboarding can be constrained by a pre-existing IAM permissions boundary
# policy. A boundary caps the maximum permissions a role can have; it grants nothing itself and must
# already exist in the account. Each value may be either a full policy ARN (used as-is) or a bare
# policy name/path without a leading slash, in which case the ARN is formed for the account the role
# is created in. Leave null (the default) to create the role without a permissions boundary.
#
# Full role name validation is delegated to the sub modules.
#######################################################################################
variable "organization_role_permissions_boundary" {
  description = "Optional. A pre-existing IAM permissions boundary policy to attach to the Organization (discovery) role, which is created in the management account. This constrains the maximum permissions the role can have and does not grant any permissions itself - the boundary policy must already exist in that account and must allow the AWS Organizations and CloudFormation permissions the role needs. You may provide either the full policy ARN (e.g. `arn:aws:iam::123456789012:policy/MyBoundary`) or just the policy name including any path but WITHOUT a leading slash (e.g. `MyBoundary` or `team/security/MyBoundary`), in which case the ARN is formed as `arn:<partition>:iam::<this-account-id>:policy/<value>`. Leave unset to create the role without a permissions boundary."
  type        = string
  default     = null

  validation {
    condition     = var.organization_role_permissions_boundary == null || can(regex("^arn:[a-z0-9-]*:iam::[0-9]{12}:policy/.+$", var.organization_role_permissions_boundary)) || can(regex("^[a-zA-Z0-9+=,.@_-][a-zA-Z0-9+=,.@_/-]*$", var.organization_role_permissions_boundary))
    error_message = "Must be null, a valid IAM policy ARN, or an IAM policy name/path without a leading slash."
  }
}

variable "account_service_role_permissions_boundary" {
  description = "Optional. A pre-existing IAM permissions boundary policy to attach to the Account Service (read-only) role, in every account where the role is created (the management account and each onboarded account). This constrains the maximum permissions the role can have and does not grant any permissions itself - the boundary policy must already exist in each of those accounts. You may provide either the full policy ARN (e.g. `arn:aws:iam::123456789012:policy/MyBoundary`) or just the policy name including any path but WITHOUT a leading slash (e.g. `MyBoundary` or `team/security/MyBoundary`), in which case the ARN is formed per-account as `arn:<partition>:iam::<that-account-id>:policy/<value>`. Because a bare ARN is account-specific, prefer the name/path form for org-wide deployments so each account resolves its own local policy. Leave unset to create the role without a permissions boundary."
  type        = string
  default     = null

  validation {
    condition     = var.account_service_role_permissions_boundary == null || can(regex("^arn:[a-z0-9-]*:iam::[0-9]{12}:policy/.+$", var.account_service_role_permissions_boundary)) || can(regex("^[a-zA-Z0-9+=,.@_-][a-zA-Z0-9+=,.@_/-]*$", var.account_service_role_permissions_boundary))
    error_message = "Must be null, a valid IAM policy ARN, or an IAM policy name/path without a leading slash."
  }
}

variable "cloudscanner_administration_role_permissions_boundary" {
  description = "Optional. A pre-existing IAM permissions boundary policy to attach to the CloudScanner Administration role, which is created only in the orchestrator account. This constrains the maximum permissions the role can have and does not grant any permissions itself - the boundary policy must already exist in that account. You may provide either the full policy ARN (e.g. `arn:aws:iam::123456789012:policy/MyBoundary`) or just the policy name including any path but WITHOUT a leading slash (e.g. `MyBoundary` or `team/security/MyBoundary`), in which case the ARN is formed as `arn:<partition>:iam::<account-id>:policy/<value>`. Leave unset to create the role without a permissions boundary."
  type        = string
  default     = null

  validation {
    condition     = var.cloudscanner_administration_role_permissions_boundary == null || can(regex("^arn:[a-z0-9-]*:iam::[0-9]{12}:policy/.+$", var.cloudscanner_administration_role_permissions_boundary)) || can(regex("^[a-zA-Z0-9+=,.@_-][a-zA-Z0-9+=,.@_/-]*$", var.cloudscanner_administration_role_permissions_boundary))
    error_message = "Must be null, a valid IAM policy ARN, or an IAM policy name/path without a leading slash."
  }
}

variable "cloudscanner_execution_role_permissions_boundary" {
  description = "Optional. A pre-existing IAM permissions boundary policy to attach to the CloudScanner Execution role, in every account where the role is created (the management account and each onboarded account). This constrains the maximum permissions the role can have and does not grant any permissions itself - the boundary policy must already exist in each of those accounts. You may provide either the full policy ARN (e.g. `arn:aws:iam::123456789012:policy/MyBoundary`) or just the policy name including any path but WITHOUT a leading slash (e.g. `MyBoundary` or `team/security/MyBoundary`), in which case the ARN is formed per-account as `arn:<partition>:iam::<that-account-id>:policy/<value>`. Because a bare ARN is account-specific, prefer the name/path form for org-wide deployments so each account resolves its own local policy. Leave unset to create the role without a permissions boundary."
  type        = string
  default     = null

  validation {
    condition     = var.cloudscanner_execution_role_permissions_boundary == null || can(regex("^arn:[a-z0-9-]*:iam::[0-9]{12}:policy/.+$", var.cloudscanner_execution_role_permissions_boundary)) || can(regex("^[a-zA-Z0-9+=,.@_-][a-zA-Z0-9+=,.@_/-]*$", var.cloudscanner_execution_role_permissions_boundary))
    error_message = "Must be null, a valid IAM policy ARN, or an IAM policy name/path without a leading slash."
  }
}

variable "cloudscanner_saas_customer_assume_role_permissions_boundary" {
  description = "Optional. A pre-existing IAM permissions boundary policy to attach to the CloudScanner SaaS Customer Assume role, which is created only in the orchestrator account for SaaS deployments. This constrains the maximum permissions the role can have and does not grant any permissions itself - the boundary policy must already exist in that account. You may provide either the full policy ARN (e.g. `arn:aws:iam::123456789012:policy/MyBoundary`) or just the policy name including any path but WITHOUT a leading slash (e.g. `MyBoundary` or `team/security/MyBoundary`), in which case the ARN is formed as `arn:<partition>:iam::<account-id>:policy/<value>`. Leave unset to create the role without a permissions boundary."
  type        = string
  default     = null

  validation {
    condition     = var.cloudscanner_saas_customer_assume_role_permissions_boundary == null || can(regex("^arn:[a-z0-9-]*:iam::[0-9]{12}:policy/.+$", var.cloudscanner_saas_customer_assume_role_permissions_boundary)) || can(regex("^[a-zA-Z0-9+=,.@_-][a-zA-Z0-9+=,.@_/-]*$", var.cloudscanner_saas_customer_assume_role_permissions_boundary))
    error_message = "Must be null, a valid IAM policy ARN, or an IAM policy name/path without a leading slash."
  }
}

variable "single_account_onboarding_role_permissions_boundary" {
  description = "(Optional). Permissions boundary policy (ARN or policy name/path) to attach to the single account onboarding Lambda execution role."
  type        = string
  default     = null

  validation {
    condition     = var.single_account_onboarding_role_permissions_boundary == null || can(regex("^arn:[a-z0-9-]*:iam::[0-9]{12}:policy/.+$", var.single_account_onboarding_role_permissions_boundary)) || can(regex("^[a-zA-Z0-9+=,.@_-][a-zA-Z0-9+=,.@_/-]*$", var.single_account_onboarding_role_permissions_boundary))
    error_message = "Must be null, a valid IAM policy ARN, or an IAM policy name/path without a leading slash."
  }
}

variable "upwind_enable_self_managed_kms_key" {
  description = "Specify whether to use your own KMS customer managed key (CMK) or an Upwind managed KMS key."
  type        = bool
  default     = false
}

variable "is_virtual_organization" {
  description = "Deploy the Account Service role in Virtual Organization mode, for accounts onboarded together without an AWS Organization. There is then no Org Discovery role, so the Account Service role carries the tags Upwind would otherwise read from it."
  type        = bool
  default     = false
}

variable "upwind_cloud_organization_id" {
  description = "The Cloud Organization ID generated by Upwind (not an AWS organization ID). Required when is_virtual_organization = true."
  type        = string
  default     = null
}

variable "upwind_serverless_bucket_prefix" {
  description = "Bucket that stores the single account onboarding lambda only used for upwind managed orgs"
  type        = string
  default     = "upwind-serverless-functions"
  validation {
    condition     = length(var.upwind_serverless_bucket_prefix) > 0
    error_message = "The Upwind Serverless bucket host must not be empty."
  }
}

variable "upwind_single_account_onboarding_lambda_enabled" {
  description = "Whether to create the single account onboarding Lambda (and its supporting IAM role, secret and log group). Only applies when is_virtual_organization = true."
  type        = bool
  default     = true
}

variable "deployment_region" {
  description = "Upwind SaaS Region"
  type        = string
  default     = "us"
  validation {
    condition     = contains(["us", "eu", "ap", "au", "dev"], var.deployment_region)
    error_message = "deployment_region must be one of us, eu, ap, au, dev."
  }
}

variable "enable_securityhub_integration" {
  type        = bool
  default     = false
  description = "Allow the Account Service role to publish Upwind findings into this account's AWS Security Hub (securityhub:BatchImportFindings)."
}
