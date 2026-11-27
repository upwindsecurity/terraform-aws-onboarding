data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_role" "organization_service_role" {

  name = var.org_discovery_role_name
  path = (var.iam_role_path != "/") ? var.iam_role_path : null
  # Optionally constrain the role with a caller-supplied permissions boundary (null when none was provided).
  permissions_boundary = local.permissions_boundary_arn
  description          = ""
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = "arn:${data.aws_partition.current.partition}:iam::${var.trusted_account_id}:root" }
        Action    = "sts:AssumeRole"
        Condition = {
          StringEquals = { "sts:ExternalId" = var.external_id }
        }
      }
    ]
  })


  # The Upwind backend use tags on the roles for system discovery. These tags must not be altered.
  tags = merge(
    var.custom_tags,
    {
      "upwind:aws:Component"              = "Onboarding"
      "upwind:aws:ReleaseVersion"         = local.upwind_version
      "upwind:aws:AccountServiceRoleName" = "${var.iam_role_path}${var.account_service_role_name}"
      "upwind:aws:SSMParameterPrefix"     = "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.region}:${local.orchestrator_account_id}:parameter${var.ssm_parameter_prefix}"
      "upwind:aws:CloudScannerSaaSMode"   = var.is_saas_mode ? "Enabled" : "Disabled"
    },
    local.orchestrator_account_id != "" ? {
      # The default orchestrator account followed by any additional ones, ':'-separated (IAM tag values cannot
      # contain commas).
      "upwind:aws:OrchestratorAccountId" = join("", var.additional_orchestrator_account_ids) != "" ? join(":", [local.orchestrator_account_id, join(":", var.additional_orchestrator_account_ids)]) : local.orchestrator_account_id
    } : {},
    local.orchestrator_account_id != "" && !var.is_saas_mode ? {
      "upwind:aws:CloudScannerAdministrationRoleName" = "${var.iam_role_path}${var.cloudscanner_admin_role_name}"
    } : {},
    local.orchestrator_account_id != "" && var.is_saas_mode && var.cloudscanner_saas_customer_assume_role_name != null ? {
      "upwind:aws:CustomerAssumeRoleName" = "${var.iam_role_path}${var.cloudscanner_saas_customer_assume_role_name}"
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

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "GetOrgRoleTags"
        Effect   = "Allow"
        Action   = ["iam:GetRole"]
        Resource = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role${var.iam_role_path}${var.org_discovery_role_name}"
      }
    ]
  })
}
