variable "upwind_organization_id" {
  description = "The identifier of the Upwind organization to integrate with."
  type        = string

  validation {
    # Upwind orgs are defined with the "org_" prefix
    condition     = can(regex("^org_", var.upwind_organization_id))
    error_message = "When registering the Org discovery role, the Upwind Org ID must be provided."
  }
}

variable "upwind_region" {
  type        = string
  description = "Which Upwind region to communicate with. 'us', 'eu' or 'me', or custom region."
  default     = "us"
}

variable "upwind_auth_client_id" {
  description = "The client ID used for authentication with the Upwind Authorization Service."
  type        = string
  default     = null
}

variable "upwind_auth_secret_value" {
  description = "The client secret for authentication with the Upwind Authorization Service."
  type        = string
  default     = null
}

variable "upwind_auth_secret_arn" {
  description = "The ARN of a secret containing the org registration secret."
  type        = string
  default     = null
}

variable "upwind_auth_endpoint" {
  description = "The Authentication API endpoint."
  type        = string
  default     = "https://auth.upwind.io"
}

variable "upwind_integration_endpoint" {
  description = "The Integration API endpoint."
  type        = string
  default     = "https://integration.upwind.io"
}

variable "role_arn" {
  description = "The ARN of the Org discovery role which is to be registered."
  type        = string

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:role/[a-zA-Z0-9+=,.@_-]+$", var.role_arn))
    error_message = "The role ARN is invalid."
  }
}