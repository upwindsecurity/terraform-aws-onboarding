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
    },
    var.orchestrator_account_id != "" ? {
      "upwind:aws:CloudScannerAdministrationRoleName" = var.cloudscanner_admin_role_name
      "upwind:aws:CloudScannerExecutionRoleName"      = var.cloudscanner_execution_role_name
      "upwind:aws:OrchestratorAccountId"              = var.orchestrator_account_id
      "upwind:aws:HasDSPMPermissions"                 = var.upwind_feature_dspm_enabled ? "Yes" : "No"

    } : {},

    # The following tags are duplicates of the above. Ideally we should remove them.
    {
      "upwind::AccountServiceRoleName" = var.account_service_role_name
    },
    var.orchestrator_account_id != "" ? {
      "upwind::CloudScannerAdministrationRoleName" = var.cloudscanner_admin_role_name
      "upwind::CloudScannerExecutionRoleName"      = var.cloudscanner_execution_role_name
      "upwind::OrchestratorAccountId"              = var.orchestrator_account_id
    } : {}
  )
}

resource "aws_iam_role_policy_attachment" "organization_service_role_orgreadonly_policy_attachment" {
  role       = aws_iam_role.organization_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSOrganizationsReadOnlyAccess"
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
