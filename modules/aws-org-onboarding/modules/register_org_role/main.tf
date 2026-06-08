locals {
  # Retrieve the secret from the ARN otherwise, use the values provided.
  register_client_ssm_secret = try(jsondecode(data.aws_secretsmanager_secret_version.upwind_register_credentials[0].secret_string), {})
  register_client_id         = try(coalesce(var.upwind_auth_client_id, try(local.register_client_ssm_secret.client_id, null)), null)
  register_client_secret     = try(coalesce(var.upwind_auth_secret_value, try(local.register_client_ssm_secret.client_secret, null)), null)
  upwind_access_token        = try(jsondecode(data.http.upwind_get_access_token_request.response_body).access_token, null)
  registration_response      = try(jsondecode(one(data.http.upwind_register_org_arn[*].response_body)), null)
  response_status_code       = one(data.http.upwind_register_org_arn[*].status_code)
  response_error             = local.response_status_code != 200 ? "Request returned status code:${local.response_status_code}" : null
  registration_state = local.response_error != null ? local.response_error : (
    local.registration_response == "null" ? "empty response" : (
      local.registration_response.is_valid ? "Registration succeeded" : "Registration failed"
    )
  )

}

data "aws_secretsmanager_secret_version" "upwind_register_credentials" {
  count     = var.upwind_auth_secret_arn != null ? 1 : 0
  secret_id = var.upwind_auth_secret_arn
}

data "http" "upwind_get_access_token_request" {
  method = "POST"

  url = format(
    "%s/oauth/token",
    var.upwind_region == "us"
    ? var.upwind_auth_endpoint
    : replace(var.upwind_auth_endpoint, ".upwind.", format(".%s.upwind.", var.upwind_region))
  )

  request_headers = {
    "Content-Type" = "application/x-www-form-urlencoded"
  }

  request_body = join("&", [
    "grant_type=client_credentials",
    format(
      "audience=%s",
      var.upwind_region == "us"
      ? var.upwind_integration_endpoint
      : replace(var.upwind_integration_endpoint, ".upwind.", format(".%s.upwind.", var.upwind_region))
    ),
    "client_id=${local.register_client_id}",
    "client_secret=${local.register_client_secret}",
  ])

  retry {
    attempts = 3
  }

  lifecycle {
    precondition {
      condition     = local.register_client_id != null && local.register_client_secret != null
      error_message = "Invalid client credentials. Please verify your client ID and client secret."
    }
  }
}

data "http" "upwind_register_org_arn" {
  method = "POST"

  url = format(
    "%s/v1/organizations/%s/organizational-credentials/aws/validate?include-discovery=true",
    var.upwind_region == "us" ? var.upwind_integration_endpoint : replace(var.upwind_integration_endpoint, ".upwind.", format(".%s.upwind.", var.upwind_region)),
    var.upwind_organization_id,
  )

  request_headers = {
    "Content-Type"  = "application/json"
    "Authorization" = format("Bearer %s", local.upwind_access_token)
  }

  request_body = jsonencode(
    {
      "audit_role_arn" = var.role_arn
    }
  )

  retry {
    attempts     = 3
    min_delay_ms = 10000
    max_delay_ms = 30000
  }

  lifecycle {
    precondition {
      condition     = local.upwind_access_token != null
      error_message = "Unable to obtain access token. Please verify your client ID and client secret. Error: ${data.http.upwind_get_access_token_request.response_body}"
    }

    precondition {
      condition     = var.upwind_organization_id != null
      error_message = "The Upwind Organization must be provided when registering the Org discovery role."
    }

    postcondition {
      condition     = contains([200, 201], self.status_code)
      error_message = "Unexpected status code returned when registering discovery role: ${self.status_code}"
    }
  }
}
