resource "aws_secretsmanager_secret" "cloudscanner_secret" {

  name                    = var.secret_name
  recovery_window_in_days = 0

  tags = merge(
    var.custom_tags,
    {
      "upwind:aws:Component"      = "Onboarding",
      "upwind:aws:ReleaseVersion" = local.upwind_version
    }
  )
}

resource "aws_secretsmanager_secret_version" "cloudscanner_credentials" {
  secret_id = aws_secretsmanager_secret.cloudscanner_secret.arn

  secret_string = jsonencode({
    clientId     = trimspace(var.auth_client_id)
    clientSecret = trimspace(var.auth_secret_value)
  })
}

