data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "execution_permissions" {
  statement {
    sid       = "GetSecret"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.upwind_client_credentials_secret_arn]
    effect    = "Allow"
  }
  statement {
    sid       = "LambdaExecutionPermission"
    actions   = ["logs:PutLogEvents", "logs:CreateLogStream"]
    resources = ["${aws_cloudwatch_log_group.single_account_onboarding.arn}:*"]
    effect    = "Allow"
  }
  statement {
    sid       = "DeleteSelf"
    actions   = ["lambda:DeleteFunction"]
    resources = [local.function_arn]
    effect    = "Allow"
  }
  statement {
    sid       = "GetCallerIdentity"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
    effect    = "Allow"
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name = local.role_name
  path = var.iam_role_path
  # Optionally constrain the role with a caller-supplied permissions boundary (null when none was provided).
  permissions_boundary = local.permissions_boundary_arn
  assume_role_policy   = data.aws_iam_policy_document.assume_role.json

  tags = local.tags
}

resource "aws_iam_role_policy" "lambda_execution_policy" {
  name   = "UpwindLambdaExecution"
  policy = data.aws_iam_policy_document.execution_permissions.json
  role   = aws_iam_role.lambda_execution_role.name
}