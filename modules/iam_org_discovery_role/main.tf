data "aws_partition" "current" {}

resource "aws_iam_role" "organization_service_role" {

  name        = var.org_discovery_role_name
  description = ""
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow",
          Principal = {
            "AWS" = [
              var.trusted_arn
            ]
          },
          Action = "sts:AssumeRole",
          Condition = {
            "StringEquals" = {
              "sts:ExternalId" = var.external_id
            }
          }
        }
      ]
    }
  )


  # The Upwind backend use tags on the roles for system discovery. These tags must not be altered.
  tags = merge(
    var.custom_tags,
    {
      "upwind:aws:Component"              = "Onboarding",
      "upwind:aws:ReleaseVersion"         = local.upwind_version
      "upwind:aws:AccountServiceRoleName" = var.account_service_role_name
      "upwind:aws:CloudScannerSaaSMode"   = var.is_saas_mode ? "Enabled" : "Disabled"
    },
    # The orchestrator tags are always present so the Upwind backend sees a
    # stable set of tag keys; when no orchestrator account is configured they
    # carry empty/"No" values instead of being omitted.
    {
      "upwind:aws:CloudScannerAdministrationRoleName" = local.has_orchestrator_account ? var.cloudscanner_admin_role_name : ""
      "upwind:aws:CloudScannerExecutionRoleName"      = local.has_orchestrator_account ? var.cloudscanner_execution_role_name : ""
      "upwind:aws:OrchestratorAccountId"              = local.has_orchestrator_account ? var.orchestrator_account_id : ""
      "upwind:aws:HasDSPMPermissions"                 = local.has_orchestrator_account && var.upwind_feature_dspm_enabled ? "Yes" : "No"
      "upwind:aws:HasDSPMRDSPermissions"              = local.has_orchestrator_account && var.upwind_feature_dspm_rds_enabled ? "Yes" : "No"
      "upwind:aws:HasCSAutomationPermissions"         = local.has_orchestrator_account && var.upwind_cloudscanner_management_enabled ? "Yes" : "No"
    },

    # The following tags are duplicates of the above. Ideally we should remove them.
    {
      "upwind::AccountServiceRoleName" = var.account_service_role_name
    },
    {
      "upwind::CloudScannerAdministrationRoleName" = local.has_orchestrator_account ? var.cloudscanner_admin_role_name : ""
      "upwind::CloudScannerExecutionRoleName"      = local.has_orchestrator_account ? var.cloudscanner_execution_role_name : ""
      "upwind::OrchestratorAccountId"              = local.has_orchestrator_account ? var.orchestrator_account_id : ""
    },
    var.cloudscanner_saas_customer_assume_role_name != null ? {
      "upwind:aws:CustomerAssumeRoleName" = var.cloudscanner_saas_customer_assume_role_name
    } : {}
  )
}

resource "aws_iam_role_policy_attachment" "organization_service_role_orgreadonly_policy_attachment" {
  role       = aws_iam_role.organization_service_role.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AWSOrganizationsReadOnlyAccess"
}

resource "aws_iam_role_policy" "organization_service_role_viewroletags_access_policy" {
  name = "AllowViewRoleTags"
  role = aws_iam_role.organization_service_role.name

  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Action = [
            "iam:GetRole"
          ],
          Resource = aws_iam_role.organization_service_role.arn,
          Effect   = "Allow",
          Sid      = "GetOrgRoleTags"
        }
      ]
    }
  )
}
