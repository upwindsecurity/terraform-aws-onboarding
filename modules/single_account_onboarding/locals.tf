data "aws_partition" "this" {}
data "aws_region" "this" {}
data "aws_caller_identity" "this" {}

locals {
  # The upwind_version is stamped by scripts/inject-version.sh as part of the release process.
  upwind_version = "TF-4.9.1"

  tags = merge(
    var.custom_tags,
    {
      "upwind:aws:Component"      = "Onboarding",
      "upwind:aws:ReleaseVersion" = local.upwind_version
    }
  )

  # Resolve the optional permissions boundary. A value beginning with "arn:" is used verbatim; a bare
  # policy name/path is expanded to a full ARN for this account. Null when no boundary was supplied.
  permissions_boundary_arn = (
    var.permissions_boundary == null ? null :
    can(regex("^arn:", var.permissions_boundary)) ? var.permissions_boundary :
    "arn:${data.aws_partition.this.partition}:iam::${data.aws_caller_identity.this.account_id}:policy/${var.permissions_boundary}"
  )

  # Upwind endpoints per SaaS deployment region. US uses the root upwind.io domain, other production regions
  # use a regional subdomain (<region>.upwind.io) and dev uses upwind.dev.
  upwind_region_endpoints = {
    us = {
      auth_url      = "https://oauth.upwind.io/oauth/token"
      api_url       = "https://integration.upwind.io/api/v1"
      auth_audience = "https://agent.upwind.io"
    }
    eu = {
      auth_url      = "https://oauth.eu.upwind.io/oauth/token"
      api_url       = "https://integration.eu.upwind.io/api/v1"
      auth_audience = "https://agent.eu.upwind.io"
    }
    ap = {
      auth_url      = "https://oauth.ap.upwind.io/oauth/token"
      api_url       = "https://integration.ap.upwind.io/api/v1"
      auth_audience = "https://agent.ap.upwind.io"
    }
    me = {
      auth_url      = "https://oauth.me.upwind.io/oauth/token"
      api_url       = "https://integration.me.upwind.io/api/v1"
      auth_audience = "https://agent.me.upwind.io"
    }
    dev = {
      auth_url      = "https://oauth.upwind.dev/oauth/token"
      api_url       = "https://integration.upwind.dev/api/v1"
      auth_audience = "https://agent.upwind.dev"
    }
  }

  upwind_auth_url      = local.upwind_region_endpoints[var.deployment_region].auth_url
  upwind_api_url       = local.upwind_region_endpoints[var.deployment_region].api_url
  upwind_auth_audience = local.upwind_region_endpoints[var.deployment_region].auth_audience

  role_name     = var.role_name_suffix != "" ? join("-", [var.upwind_lambda_execution_role_name, var.role_name_suffix]) : var.upwind_lambda_execution_role_name
  function_name = var.role_name_suffix != "" ? join("-", [var.upwind_onboarding_lambda_name_prefix, var.role_name_suffix]) : var.upwind_onboarding_lambda_name_prefix
  function_arn  = "arn:${data.aws_partition.this.partition}:lambda:${data.aws_region.this.region}:${data.aws_caller_identity.this.account_id}:function:${local.function_name}"
  s3_bucket     = join("-", [trimsuffix(var.upwind_serverless_bucket_prefix, "-"), data.aws_region.this.name])
  s3_key        = "single-account-onboarding/single-account-onboarding.zip"
}
