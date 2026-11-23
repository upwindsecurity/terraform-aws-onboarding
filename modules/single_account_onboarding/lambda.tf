resource "aws_lambda_function" "single_account_onboarding" {
  function_name = local.function_name
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "upwind_single_account_onboard.lambda_handler"
  runtime       = "python3.14"
  s3_bucket     = local.s3_bucket
  s3_key        = local.s3_key

  logging_config {
    log_format = "JSON"
    log_group  = aws_cloudwatch_log_group.single_account_onboarding.name
  }

  environment {
    variables = {
      UPWIND_AUTH_URL               = local.upwind_auth_url
      UPWIND_API_URL                = local.upwind_api_url
      UPWIND_AUTH_AUDIENCE          = local.upwind_auth_audience
      UPWIND_CLIENT_CREDENTIALS_ARN = var.upwind_client_credentials_secret_arn
      UPWIND_CLOUD_ORG_ID           = var.cloud_organization_id
    }
  }

  tags    = local.tags
  timeout = 30
}

resource "aws_lambda_invocation" "single_account_onboarding" {
  function_name   = aws_lambda_function.single_account_onboarding.function_name
  input           = jsonencode({})
  lifecycle_scope = "CREATE_ONLY"
  depends_on      = [aws_iam_role_policy.lambda_execution_policy]
}


resource "aws_cloudwatch_log_group" "single_account_onboarding" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 1

  tags = local.tags
}
