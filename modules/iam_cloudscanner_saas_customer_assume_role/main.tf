data "aws_partition" "current" {}

resource "aws_iam_role" "cloudscanner_saas_customer_assume_role" {
  name        = var.role_name
  description = "Grants Upwind Security the necessary permissions to assume the CloudScanner Execution role to perform scanning operations."

  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Principal = {
            AWS = "arn:aws:iam::${var.saas_trusted_account_id}:root"
          }
          Action = "sts:AssumeRole"
          Condition = {
            StringEquals = {
              "sts:ExternalId" = var.external_id
            }
          }
        }
      ]
    }
  )

  tags = merge(
    var.custom_tags,
    {
      "upwind:aws:Component"      = "Onboarding"
      "upwind:aws:ReleaseVersion" = local.upwind_version
    }
  )
}

resource "aws_iam_role_policy" "cloudscanner_saas_customer_assume_role_policy" {
  name = "CloudScannerAssumeExecutionRolePolicy"
  role = aws_iam_role.cloudscanner_saas_customer_assume_role.name

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Sid      = "PermitExecutionRoleAssumption"
          Effect   = "Allow"
          Action   = ["sts:AssumeRole"]
          Resource = "arn:${data.aws_partition.current.partition}:iam::*:role/${var.cloudscanner_execution_role_name}"
        }
      ]
    }
  )
}
