data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "cloudscanner_saas_customer_assume_role" {
  name = var.role_name
  path = (var.iam_role_path != "/") ? var.iam_role_path : null
  # Optionally constrain the role with a caller-supplied permissions boundary (null when none was provided).
  permissions_boundary = local.permissions_boundary_arn
  description          = "Grants Upwind Security the necessary permissions to assume the CloudScanner Execution role to perform scanning operations."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          # IAM expands an account id principal to that account's root.
          AWS = var.saas_trusted_account_id
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = { "sts:ExternalId" = var.external_id }
        }
      }
    ]
  })

  tags = merge(
    var.custom_tags,
    {
      "upwind:aws:Component"             = "Onboarding"
      "upwind:aws:ReleaseVersion"        = local.upwind_version
      "upwind:aws:HasDSPMPermissions"    = var.dspm_enabled ? "Yes" : "No"
      "upwind:aws:HasDSPMRDSPermissions" = var.dspm_rds_enabled ? "Yes" : "No"
      "upwind:aws:CloudScannerExecutionRoleName" = join("", [
        var.iam_role_path,
        var.cloudscanner_execution_role_name
      ])
    },
  )
}

resource "aws_iam_role_policy" "cloudscanner_saas_customer_assume_role_policy" {
  name = "CloudScannerAssumeExecutionRolePolicy"
  role = aws_iam_role.cloudscanner_saas_customer_assume_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid      = "PermitExecutionRoleAssumption"
          Effect   = "Allow"
          Action   = ["sts:AssumeRole"]
          Resource = "arn:${data.aws_partition.current.partition}:iam::*:role${var.iam_role_path}${var.cloudscanner_execution_role_name}"
        }
      ],
      (join("", var.outpost_only_account_ids) != "") ? [
        {
          # Explicit deny policy to block SaaS on Outpost only accounts
          Sid      = "DenyExecutionRoleAssumptionInSaaSBlockedAccounts"
          Effect   = "Deny"
          Action   = ["sts:AssumeRole"]
          Resource = "arn:${data.aws_partition.current.partition}:iam::*:role${var.iam_role_path}${var.cloudscanner_execution_role_name}"
          Condition = {
            StringEquals = { "aws:ResourceAccount" = var.outpost_only_account_ids }
          }
        }
      ] : []
    )
  })
}
