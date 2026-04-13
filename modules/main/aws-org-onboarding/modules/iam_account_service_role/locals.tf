locals {
  upwind_version = "VERSION_UNDEFINED"

  upwind_cfn_sources = [
    "https://s3.amazonaws.com/get.upwind.io/cfn/templates/*",
    "https://s3.us-east-1.amazonaws.com/get.upwind.io/cfn/templates/*"
  ]
}
