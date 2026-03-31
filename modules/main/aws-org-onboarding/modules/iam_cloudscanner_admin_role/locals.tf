locals {
  upwind_version = "VERSION_UNDEFINED"

  # Secret ARNs include a random suffix. We will strip that to use and ARNlike condition that allows the secret to be 
  # updated if necessary
  arn_parts                   = split("-", var.cloudscanner_secret_arn)
  cloudscanner_secret_arnlike = "${join("-", slice(local.arn_parts, 0, length(local.arn_parts) - 1))}*"
}
