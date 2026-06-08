variable "external_id" {
  type = string
}

variable "upwind_org_register_auth_client_id" {
  type = string
}

variable "upwind_org_register_auth_secret_value" {
  type = string
  sensitive = true
}

variable "upwind_organization_id" {
  type = string
}

variable "upwind_trusted_account_id" {
  type = string
}

variable "orchestrator_account_id" {
  type = string
}

variable "management_account_id" {
  type = string
}

variable "install_roles_in_management_account" {
  type = bool
}

variable "role_name_suffix" {
  type = string
}

variable "upwind_include_ec2_network_management_permissions" {
  type = bool
}

variable "upwind_cloudscanner_auth_client_id" {
  type = string
}

variable "upwind_cloudscanner_auth_secret_value" {
  type      = string
  sensitive = true
}