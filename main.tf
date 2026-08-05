# This module can be applied to each AWS account within the organisations seperately,
# and will create IAM roles and resources for each account as described in the README.

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

# The Org discovery only needs to be created in the management account
module "org_discovery_role" {
  count = local.condition_is_management_account ? 1 : 0

  source = "./modules/iam_org_discovery_role"

  trusted_arn                                 = local.upwind_trusted_arn
  external_id                                 = var.external_id
  org_discovery_role_name                     = local.organization_account_service_role_name
  orchestrator_account_id                     = var.orchestrator_account_id
  account_service_role_name                   = local.account_service_role_name
  cloudscanner_admin_role_name                = local.cloudscanner_admin_role_name
  cloudscanner_execution_role_name            = local.cloudscanner_execution_role_name
  upwind_feature_dspm_enabled                 = var.upwind_feature_dspm_enabled
  upwind_feature_dspm_rds_enabled             = var.upwind_feature_dspm_rds_enabled
  is_saas_mode                                = local.condition_is_saas_mode
  cloudscanner_saas_customer_assume_role_name = local.condition_is_saas_mode ? local.cloudscanner_saas_customer_assume_role_name : null
  upwind_cloudscanner_management_enabled      = var.upwind_cloudscanner_management_enabled
  custom_tags                                 = var.custom_tags
}

# The Account Service role will be installed in all accounts but for the management account
# where it is only installed optionally.
module "account_service_role" {
  count = (!local.condition_is_management_account ||
  (local.condition_is_management_account && var.install_roles_in_management_account)) ? 1 : 0

  depends_on = [module.cloudscanner_secret]

  source = "./modules/iam_account_service_role"

  trusted_arn                      = local.upwind_trusted_arn
  external_id                      = var.external_id
  account_service_role_name        = local.account_service_role_name
  cloudscanner_admin_role_name     = local.cloudscanner_admin_role_name
  cloudscanner_execution_role_name = local.cloudscanner_execution_role_name
  custom_tags                      = var.custom_tags

  # Pass the names for the managed policies
  account_service_cloudformation_policy_name           = local.account_service_role_cloudformation_policy_name
  account_service_cloudscanner_ec2_policy_name         = local.account_service_role_cloudscanner_ec2_policy_name
  account_service_cloudscanner_policy_name             = local.account_service_role_cloudscanner_policy_name
  account_service_cloudscanner_ec2_network_policy_name = local.account_service_cloudscanner_ec2_network_policy_name

  # Set the secret - either to the created secret or the ARN provided
  cloudscanner_secret_arn = local.condition_create_cloudscanner_secret ? one(module.cloudscanner_secret[*]).secret.arn : var.upwind_cloudscanner_auth_secret_arn

  # The management account could be chosen as the orchestrator account (not recommended), so the role should be
  # created with the additional permissions
  # In SaaS mode the admin role and management policies are not created, so apply_for_orchestrator_account is false.
  apply_for_orchestrator_account = local.condition_is_orchestrator_account && !local.condition_is_saas_mode

  # Provide conditional features
  upwind_feature_dspm_enabled                       = var.upwind_feature_dspm_enabled
  upwind_feature_dspm_rds_enabled                   = var.upwind_feature_dspm_rds_enabled
  upwind_cloudscanner_management_enabled            = var.upwind_cloudscanner_management_enabled
  upwind_include_ec2_network_management_permissions = var.upwind_include_ec2_network_management_permissions

  # Agentless Kubernetes
  upwind_agentless_k8s_access_entries_enabled              = var.upwind_agentless_k8s_access_entries_enabled
  upwind_agentless_k8s_ssm_enabled                         = var.upwind_agentless_k8s_ssm_enabled
  upwind_agentless_k8s_eks_admin_view_policy_enabled       = var.upwind_agentless_k8s_eks_admin_view_policy_enabled
  upwind_agentless_k8s_account_whitelist                   = var.upwind_agentless_k8s_account_whitelist
  current_account_id                                       = data.aws_caller_identity.current.account_id
  account_service_agentless_k8s_access_entries_policy_name = local.account_service_agentless_k8s_access_entries_policy_name
  account_service_agentless_k8s_ssm_policy_name            = local.account_service_agentless_k8s_ssm_policy_name

  # SaaS mode tags
  is_saas_mode                                = local.condition_is_saas_mode
  cloudscanner_saas_customer_assume_role_name = local.condition_create_customer_assume_role ? local.cloudscanner_saas_customer_assume_role_name : null
}

# Create the CloudScanner admin role. This will be in the orchestrator account.
module "cloudscanner_admin_role" {
  count = (local.condition_is_orchestrator_account && !local.condition_is_saas_mode) ? 1 : 0

  source = "./modules/iam_cloudscanner_admin_role"

  cloudscanner_admin_role_name     = local.cloudscanner_admin_role_name
  cloudscanner_execution_role_name = local.cloudscanner_execution_role_name
  custom_tags                      = var.custom_tags

  # Set the secret - either to the created secret or the ARN provided
  cloudscanner_secret_arn = local.condition_create_cloudscanner_secret ? one(module.cloudscanner_secret[*]).secret.arn : var.upwind_cloudscanner_auth_secret_arn
}

# The CloudScanner execution role should be created in all accounts which are to be scanned. Optionally,
# this may include the management account.
module "cloudscanner_execution_role" {
  count = (local.condition_has_orchestrator_account_id &&
  (!local.condition_is_management_account || (local.condition_is_management_account && var.install_roles_in_management_account))) ? 1 : 0

  source = "./modules/iam_cloudscanner_execution_role"

  orchestrator_account_id          = var.orchestrator_account_id
  cloudscanner_admin_role_name     = local.cloudscanner_admin_role_name
  cloudscanner_execution_role_name = local.cloudscanner_execution_role_name
  custom_tags                      = var.custom_tags

  # Provide conditional features
  upwind_feature_dspm_enabled           = var.upwind_feature_dspm_enabled
  upwind_feature_dspm_account_whitelist = var.upwind_feature_dspm_account_whitelist

  upwind_feature_dspm_rds_enabled           = var.upwind_feature_dspm_rds_enabled
  upwind_feature_dspm_rds_account_allowlist = var.upwind_feature_dspm_rds_account_allowlist

  # SaaS mode trust policy
  is_saas_mode                                = local.condition_is_saas_mode
  cloudscanner_saas_customer_assume_role_name = local.cloudscanner_saas_customer_assume_role_name
}

# ------------------------------------------------------------------------------------------------
# DSPM RDS scanning permissions (mirrors the CloudFormation v2 CloudScannerDspmRds*ManagedPolicy in
# integration-aws-cloudformation). A single shared control-plane managed policy is attached to BOTH the
# CloudScanner administration role (the executor lambda runs as it) and the execution role (assumed
# cross-account for the member-side snapshot / re-encrypt / share / delete), plus an administration-role-only
# VPC ENI policy for the in-VPC executor lambda. Managed rather than inline so they do not count against
# either role's inline-policy size budget. Created only when DSPM RDS is enabled for this account. Creates
# and copies require our tag on the new resource (aws:RequestTag); modifies, shares, and deletes are
# restricted to our own tagged resources (aws:ResourceTag).
# ------------------------------------------------------------------------------------------------
resource "aws_iam_policy" "cloudscanner_dspm_rds" {
  # Gated by upwind_feature_dspm_rds_enabled, which defaults to false.
  count = local.dspm_rds_enabled && (length(module.cloudscanner_execution_role) > 0 || length(module.cloudscanner_admin_role) > 0) ? 1 : 0

  name        = local.cloudscanner_dspm_rds_policy_name
  description = "Upwind DSPM RDS scanning permissions: create, copy, restore, share, and delete Upwind-tagged RDS snapshots and scan copies, perform the KMS re-encryption, and log in to discover databases."

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "DspmRdsDescribe"
          Effect = "Allow"
          Action = [
            "rds:DescribeDBInstances",
            "rds:DescribeDBClusters",
            "rds:DescribeDBSnapshots",
            "rds:DescribeDBClusterSnapshots"
          ]
          Resource = "*"
        },
        {
          Sid    = "DspmRdsCreateSnapshots"
          Effect = "Allow"
          Action = [
            "rds:CreateDBSnapshot",
            "rds:CreateDBClusterSnapshot"
          ]
          Resource = [
            "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:db:*",
            "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:cluster:*",
            "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:snapshot:*",
            "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:cluster-snapshot:*"
          ]
          Condition = {
            StringEquals = {
              "aws:RequestTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          # The copy source may be a cross-account shared snapshot (untagged here, as tags do not cross
          # accounts), so only the new copy carries the tag condition and the account segment stays "*".
          Sid    = "DspmRdsCopySnapshots"
          Effect = "Allow"
          Action = [
            "rds:CopyDBSnapshot",
            "rds:CopyDBClusterSnapshot"
          ]
          Resource = [
            "arn:${data.aws_partition.current.partition}:rds:*:*:snapshot:*",
            "arn:${data.aws_partition.current.partition}:rds:*:*:cluster-snapshot:*"
          ]
          Condition = {
            StringEquals = {
              "aws:RequestTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid    = "DspmRdsRestore"
          Effect = "Allow"
          Action = [
            "rds:RestoreDBInstanceFromDBSnapshot",
            "rds:RestoreDBClusterFromSnapshot",
            "rds:CreateDBInstance"
          ]
          Resource = [
            "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:db:*",
            "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:cluster:*",
            "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:snapshot:*",
            "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:cluster-snapshot:*",
            "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:subgrp:*"
          ]
          Condition = {
            StringEquals = {
              "aws:RequestTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          # RDS authorises the Tags field on create/copy/restore as a separate action. TagKeys is restricted
          # to the single key the executor sets so this cannot stamp any other tag key.
          Sid    = "DspmRdsTagOnCreate"
          Effect = "Allow"
          Action = [
            "rds:AddTagsToResource"
          ]
          Resource = [
            "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:db:*",
            "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:cluster:*",
            "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:snapshot:*",
            "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:cluster-snapshot:*"
          ]
          Condition = {
            StringEquals = {
              "aws:RequestTag/UpwindComponent" = "CloudScanner"
            }
            "ForAllValues:StringEquals" = {
              "aws:TagKeys" = ["UpwindComponent"]
            }
          }
        },
        {
          Sid    = "DspmRdsModifyOwn"
          Effect = "Allow"
          Action = [
            "rds:ModifyDBInstance",
            "rds:ModifyDBCluster"
          ]
          Resource = [
            "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:db:*",
            "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:cluster:*"
          ]
          Condition = {
            StringEquals = {
              "aws:ResourceTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid    = "DspmRdsShareSnapshots"
          Effect = "Allow"
          Action = [
            "rds:ModifyDBSnapshotAttribute",
            "rds:ModifyDBClusterSnapshotAttribute"
          ]
          Resource = [
            "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:snapshot:*",
            "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:cluster-snapshot:*"
          ]
          Condition = {
            StringEquals = {
              "aws:ResourceTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid    = "DspmRdsDeleteOwn"
          Effect = "Allow"
          Action = [
            "rds:DeleteDBInstance",
            "rds:DeleteDBCluster",
            "rds:DeleteDBSnapshot",
            "rds:DeleteDBClusterSnapshot"
          ]
          Resource = [
            "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:db:*",
            "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:cluster:*",
            "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:snapshot:*",
            "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:cluster-snapshot:*"
          ]
          Condition = {
            StringEquals = {
              "aws:ResourceTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          # KMS for the re-encryption copy, used by RDS via kms:ViaService.
          Sid    = "DspmRdsKms"
          Effect = "Allow"
          Action = [
            "kms:DescribeKey",
            "kms:CreateGrant",
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*"
          ]
          Resource = "*"
          Condition = {
            StringLike = {
              "kms:ViaService" = "rds.*.amazonaws.com"
            }
          }
        },
        {
          # Discovery IAM token, scoped to the discovery user (must match UPWIND_DSPM_DB_USER).
          Sid    = "DspmRdsDbConnect"
          Effect = "Allow"
          Action = [
            "rds-db:connect"
          ]
          Resource = "arn:${data.aws_partition.current.partition}:rds-db:*:${data.aws_caller_identity.current.account_id}:dbuser:*/upwind_scanner"
        }
      ]
    }
  )
}

resource "aws_iam_policy" "cloudscanner_dspm_rds_vpc_access" {
  count = local.dspm_rds_enabled && length(module.cloudscanner_admin_role) > 0 ? 1 : 0

  name        = local.cloudscanner_dspm_rds_vpc_access_policy_name
  description = "VPC networking permissions (elastic network interfaces) for the in-VPC Upwind DSPM RDS scanning lambda."

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "DspmRdsExecutorVpcEni"
          Effect = "Allow"
          Action = [
            "ec2:CreateNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface",
            "ec2:AssignPrivateIpAddresses",
            "ec2:UnassignPrivateIpAddresses"
          ]
          Resource = "*"
        }
      ]
    }
  )
}

# Attach the shared control-plane policy to the execution role (member-side ops via cross-account assume).
resource "aws_iam_role_policy_attachment" "cloudscanner_execution_role_dspm_rds" {
  count = local.dspm_rds_enabled && length(module.cloudscanner_execution_role) > 0 ? 1 : 0

  role       = module.cloudscanner_execution_role[0].iam_role.name
  policy_arn = aws_iam_policy.cloudscanner_dspm_rds[0].arn
}

# Attach the shared control-plane policy to the administration role (the executor lambda runs as it).
resource "aws_iam_role_policy_attachment" "cloudscanner_admin_role_dspm_rds" {
  count = local.dspm_rds_enabled && length(module.cloudscanner_admin_role) > 0 ? 1 : 0

  role       = module.cloudscanner_admin_role[0].iam_role.name
  policy_arn = aws_iam_policy.cloudscanner_dspm_rds[0].arn
}

# Attach the VPC ENI policy to the administration role only (only it runs the in-VPC executor lambda).
resource "aws_iam_role_policy_attachment" "cloudscanner_admin_role_dspm_rds_vpc_access" {
  count = local.dspm_rds_enabled && length(module.cloudscanner_admin_role) > 0 ? 1 : 0

  role       = module.cloudscanner_admin_role[0].iam_role.name
  policy_arn = aws_iam_policy.cloudscanner_dspm_rds_vpc_access[0].arn
}

# Create the CloudScanner secret in the orchestrator account if not using a provided ARN.
# If the orchestrator account is the management account, only create the secret if the install roles
# has been configured
module "cloudscanner_secret" {
  count = local.condition_create_cloudscanner_secret ? 1 : 0

  source = "./modules/cloudscanner_auth_secret"

  secret_name       = local.cloudscanner_secret_name
  auth_client_id    = var.upwind_cloudscanner_auth_client_id
  auth_secret_value = var.upwind_cloudscanner_auth_secret_value
  custom_tags       = var.custom_tags
}

# In SaaS mode, create the customer assume role in the orchestrator account.
# Upwind's SaaS account assumes this role to perform scanning operations.
module "cloudscanner_saas_customer_assume_role" {
  count = local.condition_create_customer_assume_role ? 1 : 0

  source = "./modules/iam_cloudscanner_saas_customer_assume_role"

  role_name                        = local.cloudscanner_saas_customer_assume_role_name
  saas_trusted_account_id          = local.saas_trusted_account_id
  external_id                      = var.external_id
  cloudscanner_execution_role_name = local.cloudscanner_execution_role_name
  custom_tags                      = var.custom_tags
}

# Using a null resource so that we can avail of the precondition rules to
# perform extra validation when installing into the management account
resource "null_resource" "validate_management_account" {
  count = (local.condition_is_management_account) ? 1 : 0
  lifecycle {
    precondition {
      condition     = (local.condition_is_orchestrator_account && var.install_roles_in_management_account) || !local.condition_is_orchestrator_account
      error_message = "When using the Management account as the Orchestrator account, the option to install the additional roles must be enabled."
    }
  }
}

resource "null_resource" "validate_cloudscanner_auth" {
  lifecycle {

    # Only validate if orchestrator is provided AND not in SaaS mode
    precondition {
      condition = (
        local.condition_is_saas_mode ||
        !local.condition_has_orchestrator_account_id ||
        local.condition_cloudscanner_has_any_secret_config
      )
      error_message = "CloudScanner auth is required when an orchestrator account is provided. Provide either a secret ARN or client_id and client_secret."
    }

    # If NOT using ARN → client_id must exist when secret exists
    precondition {
      condition = (
        local.condition_is_saas_mode ||
        !local.condition_has_orchestrator_account_id ||
        local.condition_cloudscanner_use_arn ||
        !local.condition_cloudscanner_secret_value_provided ||
        local.condition_cloudscanner_client_id_provided
      )
      error_message = "CloudScanner auth: client_id is missing. Client Secret and ID must be provided."
    }

    # If NOT using ARN → client_secret must exist when client_id exists
    precondition {
      condition = (
        local.condition_is_saas_mode ||
        !local.condition_has_orchestrator_account_id ||
        local.condition_cloudscanner_use_arn ||
        !local.condition_cloudscanner_client_id_provided ||
        local.condition_cloudscanner_secret_value_provided
      )
      error_message = "CloudScanner auth: client_secret is missing. Client Secret and ID must be provided."
    }

    # Cannot provide both ARN and inline
    precondition {
      condition = (
        local.condition_is_saas_mode ||
        !local.condition_has_orchestrator_account_id ||
        !local.condition_cloudscanner_invalid_both_provided
      )
      error_message = "CloudScanner auth: provide either a secret ARN OR client_id/client_secret, not both."
    }

    # Prevent partial inline ONLY when not using ARN
    precondition {
      condition = (
        local.condition_is_saas_mode ||
        !local.condition_has_orchestrator_account_id ||
        local.condition_cloudscanner_use_arn ||
        !local.condition_cloudscanner_partial_inline
      )
      error_message = "CloudScanner auth: both client_id and client_secret must be provided together."
    }
  }
}

resource "null_resource" "validate_saas_config" {
  lifecycle {
    precondition {
      condition     = !local.condition_is_saas_mode || var.orchestrator_account_id != null
      error_message = "orchestrator_account_id is required when is_saas = true."
    }
  }
}

