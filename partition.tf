locals {
  partitions = {
    "aws" = {
      trusted_account    = "340457201789"
      publishing_account = "693339160499"
      templates_path     = "get.upwind.io/cfn/templates"
      template_urls      = ["https://s3.amazonaws.com/get.upwind.io/cfn/templates/*", "https://s3.us-east-1.amazonaws.com/get.upwind.io/cfn/templates/*"]
    }
    "aws-cn" = {
      trusted_account    = "720941505893"
      publishing_account = "720941505893"
      templates_path     = "upwind-get-dev-cn-northwest-1/cfn/templates"
      template_urls      = ["https://s3.cn-northwest-1.amazonaws.com.cn/upwind-get-dev-cn-northwest-1/cfn/templates/*"]
    }
    "aws-us-gov" = {
      trusted_account    = "592368114658"
      publishing_account = "592368114658"
      templates_path     = "uw-cfn-templates-knox-us-gov-east-1/cfn/templates"
      template_urls      = ["https://s3.us-gov-east-1.amazonaws.com/uw-cfn-templates-knox-us-gov-east-1/cfn/templates/*"]
    }
    "aws-dev" = {
      trusted_account    = "027696145188"
      publishing_account = "693339160499"
      templates_path     = "get.upwind.dev/cfn/templates"
      template_urls      = ["https://s3.amazonaws.com/get.upwind.dev/cfn/templates/*", "https://s3.us-east-1.amazonaws.com/get.upwind.dev/cfn/templates/*"]
    }
    "aws-cn-dev" = {
      trusted_account    = "720941505893"
      publishing_account = "720941505893"
      templates_path     = "upwind-get-dev-cn-northwest-1/cfn/templates"
      template_urls      = ["https://s3.cn-northwest-1.amazonaws.com.cn/upwind-get-dev-cn-northwest-1/cfn/templates/*"]
    }
    "aws-us-gov-dev" = {
      trusted_account    = "592368114658"
      publishing_account = "592368114658"
      templates_path     = "uw-cfn-templates-knox-us-gov-east-1/cfn/templates"
      template_urls      = ["https://s3.us-gov-east-1.amazonaws.com/uw-cfn-templates-knox-us-gov-east-1/cfn/templates/*"]
    }
  }
  # upwind_dev_environment selects the Upwind dev environment's values (the <partition>-dev entries)
  partition = local.partitions["${data.aws_partition.current.partition}${var.upwind_dev_environment ? "-dev" : ""}"]
}
