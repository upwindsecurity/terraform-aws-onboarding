
variable "secret_name" {
  description = "The name to be given to the secret."
  type        = string
}

variable "auth_client_id" {
  description = "The CloudScanner client ID for Upwind Security authentication."
  type        = string

  validation {
    condition     = var.auth_client_id != ""
    error_message = "The CloudScanner auth client ID must not be an empty string"
  }
}

variable "auth_secret_value" {
  description = "The CloudScanner client secret for Upwind Security authentication."
  type        = string

  validation {
    condition     = var.auth_secret_value != ""
    error_message = "The CloudScanner auth secret value must not be an empty string"
  }
}

variable "custom_tags" {
  description = "Custom tags which shall be applied to each resource created by the module."
  type        = map(string)
  default     = {}
}
