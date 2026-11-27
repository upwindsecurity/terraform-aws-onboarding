data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "null_resource" "validate_agentless_k8_account_whitelist" {
  lifecycle {
    precondition {
      condition = (
        length(var.upwind_agentless_k8s_account_whitelist) == 0 ||
        !(var.upwind_agentless_k8s_access_entries_enabled || var.upwind_agentless_k8s_ssm_enabled) ||
        var.current_account_id != null
      )
      error_message = "When upwind_agentless_k8s_account_whitelist is set and either agentless Kubernetes access entries or agentless Kubernetes SSM is enabled, current_account_id must also be provided so Terraform can determine resource counts during plan."
    }
  }
}

resource "aws_iam_role" "account_service_role" {
  name = var.account_service_role_name
  path = (var.iam_role_path != "/") ? var.iam_role_path : null
  # Optionally constrain the role with a caller-supplied permissions boundary (null when none was provided).
  permissions_boundary = local.permissions_boundary_arn
  description          = "Grants Upwind Security the necessary permissions to oversee and manage account-level governance, including security audits, compliance checks, and operational control."
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = "arn:${data.aws_partition.current.partition}:iam::${var.trusted_account_id}:root" }
        Action    = "sts:AssumeRole"
        Condition = {
          StringEquals = { "sts:ExternalId" = var.external_id }
        }
      }
    ]
  })

  # The Upwind backend uses tags on the roles for system discovery. These tags must not be altered.
  tags = merge(
    var.custom_tags,
    merge(
      {
        "upwind:aws:Component"                                    = "Onboarding"
        "upwind:aws:ReleaseVersion"                               = local.upwind_version
        "upwind:aws:HasDSPMPermissions"                           = local.dspm_enabled ? "Yes" : "No"
        "upwind:aws:HasDSPMRDSPermissions"                        = local.dspm_rds_enabled ? "Yes" : "No"
        "upwind:aws:HasAgentlessKubernetesAccessEntryPermissions" = local.agentless_k8s_access_entries_enabled ? "Yes" : "No"
        "upwind:aws:HasAgentlessKubernetesSSMPermissions"         = local.agentless_k8s_ssm_enabled ? "Yes" : "No"
        "upwind:aws:HasSelfManagedKMSKey"                         = var.upwind_enable_self_managed_kms_key ? "Yes" : "No"
      },
      # Virtual organization: there is no Org Discovery role, so this role carries the tags Upwind would read
      # from it.
      var.is_virtual_organization ? {
        "upwind:aws:AccountServiceRoleName" = join("", [
          var.iam_role_path,
          var.account_service_role_name
        ])
      } : {},
      (var.is_virtual_organization && local.orchestrator_account_id != "") ? {
        "upwind:aws:OrchestratorAccountId" = (join("", var.additional_orchestrator_account_ids) != "") ? join(":", [
          local.orchestrator_account_id,
          join(":", var.additional_orchestrator_account_ids)
        ]) : local.orchestrator_account_id
      } : {},
      (var.is_virtual_organization && local.orchestrator_account_id != "") && var.is_saas_mode ? {
        "upwind:aws:CustomerAssumeRoleName" = join("", [
          var.iam_role_path,
          var.cloudscanner_saas_customer_assume_role_name
        ])
      } : {},
      var.is_virtual_organization ? { "upwind:aws:SSMParameterPrefix" = "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.region}:${local.orchestrator_account_id}:parameter${local.ssm_parameter_prefix}" } : {},
      (var.is_virtual_organization && local.orchestrator_account_id != "") && (!var.is_saas_mode) ? {
        "upwind:aws:CloudScannerAdministrationRoleName" = join("", [
          var.iam_role_path,
          var.cloudscanner_admin_role_name
        ])
      } : {},
      var.is_virtual_organization ? { "upwind:aws:CloudScannerSaaSMode" = var.is_saas_mode ? "Enabled" : "Disabled" } : {}
    ),
  )
}

resource "aws_iam_role_policy_attachment" "account_service_role_policy_attachment" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/SecurityAudit"
  role       = aws_iam_role.account_service_role.name
}

resource "aws_iam_role_policy" "account_service_view_access_policy" {
  name = "ViewAccessPolicy"
  role = aws_iam_role.account_service_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AccessMQ"
        Effect = "Allow"
        Action = [
          "mq:DescribeBroker",
          "mq:ListBrokers"
        ]
        Resource = "*"
      },
      {
        Sid    = "AccessStorageGateway"
        Effect = "Allow"
        Action = [
          "storagegateway:DescribeSMBFileShares",
          "storagegateway:DescribeSMBSettings"
        ]
        Resource = "*"
      },
      {
        Sid    = "BedrockReadOnly"
        Effect = "Allow"
        Action = [
          "bedrock:Get*",
          "bedrock:List*",
          "bedrock-agentcore:Get*",
          "bedrock-agentcore:List*"
        ]
        Resource = "*"
      },
      {
        Sid    = "SageMakerReadOnly"
        Effect = "Allow"
        Action = [
          "sagemaker:List*",
          "sagemaker:Describe*",
          "sagemaker:BatchDescribeModelPackage"
        ]
        Resource = "*"
      },
      {
        Sid    = "AmazonQBusinessReadOnly"
        Effect = "Allow"
        Action = [
          "qbusiness:List*",
          "qbusiness:Get*"
        ]
        Resource = "*"
      },
      {
        Sid    = "LexV2ReadOnly"
        Effect = "Allow"
        Action = [
          "lex:ListBots",
          "lex:DescribeBot",
          "lex:ListBotAliases",
          "lex:DescribeBotAlias"
        ]
        Resource = "*"
      },
      {
        Sid    = "RekognitionReadOnly"
        Effect = "Allow"
        Action = [
          "rekognition:ListStreamProcessors",
          "rekognition:DescribeStreamProcessor"
        ]
        Resource = "*"
      },
      {
        Sid    = "ComprehendReadOnly"
        Effect = "Allow"
        Action = [
          "comprehend:ListEntitiesDetectionJobs",
          "comprehend:DescribeEntitiesDetectionJob",
          "comprehend:ListDocumentClassificationJobs",
          "comprehend:DescribeDocumentClassificationJob"
        ]
        Resource = "*"
      },
      {
        Sid      = "AccessPricing"
        Effect   = "Allow"
        Action   = ["pricing:GetProducts"]
        Resource = "*"
      },
      {
        Sid    = "AccessBackup"
        Effect = "Allow"
        Action = [
          "backup:List*",
          "backup:Describe*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AccessCloudWatch"
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      },
      {
        Sid    = "AccessLambda"
        Effect = "Allow"
        Action = [
          "lambda:GetFunctionUrlConfig",
          "lambda:GetEventSourceMapping",
          "lambda:GetFunction",
          "lambda:GetLayerVersion"
        ]
        Resource = "*"
      },
      {
        Sid    = "AccessEKS"
        Effect = "Allow"
        Action = [
          "eks:Describe*",
          "eks:List*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AccessCodeArtifact"
        Effect = "Allow"
        Action = [
          "codeartifact:DescribeDomain",
          "codeartifact:DescribeRepository",
          "codeartifact:ListDomains",
          "codeartifact:ListTagsForResource"
        ]
        Resource = "*"
      },
      {
        Sid      = "AccessAccount"
        Effect   = "Allow"
        Action   = ["account:GetContactInformation"]
        Resource = "*"
      },
      {
        Sid    = "AccessIdentityStore"
        Effect = "Allow"
        Action = [
          "identitystore:Describe*",
          "identitystore:List*",
          "identitystore:Get*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AccessS3"
        Effect = "Allow"
        Action = [
          "s3:Describe*",
          "s3:GetJobTagging",
          "s3:GetBucketLocation",
          "s3:List*"
        ]
        Resource = "*"
      },
      {
        Sid      = "AccessAirflow"
        Effect   = "Allow"
        Action   = ["airflow:GetEnvironment"]
        Resource = "*"
      },
      {
        Sid    = "AccessGlue"
        Effect = "Allow"
        Action = [
          "glue:GetConnections",
          "glue:GetCatalogImportStatus",
          "glue:GetTables",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetDatabase"
        ]
        Resource = "*"
      },
      {
        Sid      = "AccessAppFlow"
        Effect   = "Allow"
        Action   = ["appflow:DescribeFlow"]
        Resource = "*"
      },
      {
        Sid    = "AccessSSODirectory"
        Effect = "Allow"
        Action = [
          "sso-directory:Describe*",
          "sso-directory:Get*",
          "sso-directory:List*",
          "sso-directory:Search*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AccessAppStream"
        Effect = "Allow"
        Action = [
          "appstream:Describe*",
          "appstream:ListTagsForResource"
        ]
        Resource = "*"
      },
      {
        Sid    = "AccessECR"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:Get*"
        ]
        Resource = "*"
      },
      {
        Sid      = "AccessStates"
        Effect   = "Allow"
        Action   = ["states:ListTagsForResource"]
        Resource = "*"
      },
      {
        Sid    = "AccessSNS"
        Effect = "Allow"
        Action = [
          "sns:ListPlatformApplications",
          "sns:listSubscriptions",
          "sns:GetSubscriptionAttributes"
        ]
        Resource = "*"
      },
      {
        Sid      = "AccessWAF"
        Effect   = "Allow"
        Action   = ["waf:GetLoggingConfiguration"]
        Resource = "*"
      },
      {
        Sid      = "AccessWAFv2"
        Effect   = "Allow"
        Action   = ["wafv2:GetLoggingConfiguration"]
        Resource = "*"
      },
      {
        Sid      = "AccessWAFRegional"
        Effect   = "Allow"
        Action   = ["waf-regional:GetLoggingConfiguration"]
        Resource = "*"
      },
      {
        Sid      = "AccessDS"
        Effect   = "Allow"
        Action   = ["ds:ListTagsForResource"]
        Resource = "*"
      },
      {
        Sid    = "AccessEC2"
        Effect = "Allow"
        Action = [
          "ec2:Get*",
          "ec2:List*"
        ]
        Resource = "*"
      },
      {
        Sid      = "AccessGlacier"
        Effect   = "Allow"
        Action   = ["glacier:ListTagsForVault"]
        Resource = "*"
      },
      {
        Sid    = "AccessAWSBatchJobs"
        Effect = "Allow"
        Action = [
          "batch:Describe*",
          "batch:List*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "account_service_cloudformation_access_policy" {
  # The Cloudformation access policy should only be created when also creating the the orchestration role.
  count       = var.apply_for_orchestrator_account && var.upwind_cloudscanner_management_enabled ? 1 : 0
  name        = var.account_service_cloudformation_policy_name
  path        = (var.iam_role_path != "/") ? var.iam_role_path : null
  description = "Upwind Account Service IAM role policy for using Cloudformation to manage CloudScanners."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "UpwindCloudformationChangeSet"
        # Access to the ChangeSet is necessary to apply updates when using Cloudformation UpdateStack
        Effect   = "Allow"
        Action   = ["cloudformation:CreateChangeSet"]
        Resource = ["arn:${data.aws_partition.current.partition}:cloudformation:*:aws:transform/Serverless-2016-10-31"]
      },
      {
        Sid = "UpwindCloudformationUpdate"
        # Permissions necessary to perform update operations on existing stacks
        # StackSet permissions are deliberately excluded from the list of permissions
        Effect = "Allow"
        Action = [
          "cloudformation:Describe*",
          "cloudformation:List*",
          "cloudformation:Get*",
          "cloudformation:Detect*",
          "cloudformation:CancelUpdateStack",
          "cloudformation:ContinueUpdateRollback",
          "cloudformation:RollbackStack",
          "cloudformation:UpdateTerminationProtection",
          "cloudformation:TagResource",
          "cloudformation:UntagResource",
          "cloudformation:UpdateGeneratedTemplate",
          "cloudformation:StartResourceScan",
          "cloudformation:DeleteStack"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:cloudformation:*:${data.aws_caller_identity.current.account_id}:stack/upwind*",
          "arn:${data.aws_partition.current.partition}:cloudformation:*:${data.aws_caller_identity.current.account_id}:stack/Upwind*"
        ]
      },
      {
        Sid = "UpwindCloudformationCreateUpdateStackWithUrl"
        # Permissions which grant access to create and update stacks where,
        # a) the name is prefixed with Upwind/upwind
        # b) are created the whitelisted template Urls (the Upwind templates bucket in this partition)
        Effect = "Allow"
        Action = [
          "cloudformation:CreateStack",
          "cloudformation:UpdateStack"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:cloudformation:*:${data.aws_caller_identity.current.account_id}:stack/upwind*",
          "arn:${data.aws_partition.current.partition}:cloudformation:*:${data.aws_caller_identity.current.account_id}:stack/Upwind*"
        ]
        Condition = {
          StringLike = { "cloudformation:TemplateUrl" = local.template_urls }
        }
      },
      {
        Sid = "UpwindCloudformationCreateUpdateStackWithoutUrl"
        # Permit only the Upwind stacks to be updated, but with the condition that the template cannot be changed
        # This is necessary to permit changes to be applied to the stack configuration without applying a new version of the template
        Effect = "Allow"
        Action = ["cloudformation:UpdateStack"]
        Resource = [
          "arn:${data.aws_partition.current.partition}:cloudformation:*:${data.aws_caller_identity.current.account_id}:stack/upwind*",
          "arn:${data.aws_partition.current.partition}:cloudformation:*:${data.aws_caller_identity.current.account_id}:stack/Upwind*"
        ]
        Condition = {
          # The null condition needs to be handled as a string, unlike the other conditions
          # This condition asserts that the TemplateUrl must not be supplied for the permission to be granted
          Null = { "cloudformation:TemplateUrl" = "true" }
        }
      },
      {
        Sid = "AccessUpwindS3CloudformationBucket"
        # This policy is required to allow Cloudformation to fetch the template from the Upwind S3 bucket.
        Effect = "Allow"
        Action = ["s3:GetObject"]
        Resource = [
          # S3 objects are limited to buckets and cannot include accounts ids.
          "arn:${data.aws_partition.current.partition}:s3:::${local.templates_path}/*"
        ]
        Condition = {
          StringEquals = {
            # Restricting S3 Access to the Upwind publishing account
            "aws:ResourceAccount" = local.partition.publishing_account
          }
          "ForAnyValue:StringEquals" = {
            # Cloudformation URL is not partition
            "aws:CalledVia" = "cloudformation.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    var.custom_tags,
    {
      "upwind:aws:Component"      = "Onboarding",
      "upwind:aws:ReleaseVersion" = local.upwind_version
    }
  )
}

resource "aws_iam_role_policy_attachment" "attach_cloudformation_access_policy" {
  count = var.apply_for_orchestrator_account && var.upwind_cloudscanner_management_enabled ? 1 : 0

  role       = aws_iam_role.account_service_role.name
  policy_arn = one(aws_iam_policy.account_service_cloudformation_access_policy[*].arn)
}

resource "aws_iam_policy" "account_service_cloudscanner_ec2_access_policy" {
  # The CloudScanner EC2 access policy should only be created when also creating the the orchestration role.
  count       = var.apply_for_orchestrator_account && var.upwind_cloudscanner_management_enabled ? 1 : 0
  name        = var.account_service_cloudscanner_ec2_policy_name
  path        = (var.iam_role_path != "/") ? var.iam_role_path : null
  description = "Upwind Account Service IAM role policy to grant permissions to EC2 services used when managing CloudScanners."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Permissions to Create Auto Scaling Groups
      {
        Sid    = "CreateASGs"
        Effect = "Allow"
        Action = [
          "ec2:CreateTags",
          "autoscaling:CreateAutoScalingGroup",
          "autoscaling:CreateLaunchConfiguration"
        ]
        Resource = ["arn:${data.aws_partition.current.partition}:autoscaling:*:${data.aws_caller_identity.current.account_id}:autoScalingGroup*:autoScalingGroupName/upwind-cs-asg*"]
        Condition = {
          StringEquals = { "autoscaling:ResourceTag/UpwindComponent" = "CloudScanner" }
        }
      },
      # Permissions to Manage Auto Scaling Groups
      {
        Sid    = "ManageASGs"
        Effect = "Allow"
        Action = [
          "autoscaling:Describe*",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:SetInstanceProtection",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "autoscaling:CreateOrUpdateTags",
          "autoscaling:DeleteTags"
        ]
        Resource = ["arn:${data.aws_partition.current.partition}:autoscaling:*:${data.aws_caller_identity.current.account_id}:autoScalingGroup*:autoScalingGroupName/upwind-cs-asg*"]
        Condition = {
          StringEquals = { "autoscaling:ResourceTag/UpwindComponent" = "CloudScanner" }
        }
      },
      # Permissions to Remove Auto Scaling Groups
      {
        Sid    = "DeleteASGs"
        Effect = "Allow"
        Action = [
          "autoscaling:DeleteAutoScalingGroup",
          "autoscaling:DeleteLaunchConfiguration"
        ]
        Resource = ["arn:${data.aws_partition.current.partition}:autoscaling:*:${data.aws_caller_identity.current.account_id}:autoScalingGroup*:autoScalingGroupName/upwind-cs-asg*"]
        Condition = {
          StringEquals = { "autoscaling:ResourceTag/UpwindComponent" = "CloudScanner" }
        }
      },
      # Permissions to Create Launch Templates
      {
        Sid    = "CreateLaunchTemplates"
        Effect = "Allow"
        Action = [
          "ec2:CreateTags",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateLaunchTemplateVersion"
        ]
        Resource = ["arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:launch-template/*"]
        Condition = {
          StringEquals = { "aws:RequestTag/UpwindComponent" = "CloudScanner" }
        }
      },
      # Permissions to Manage Launch Templates
      {
        Sid    = "ManageLaunchTemplates"
        Effect = "Allow"
        Action = [
          "ec2:CreateLaunchTemplateVersion",
          "ec2:ModifyLaunchTemplate",
          "ec2:DeleteLaunchTemplate",
          "ec2:DeleteLaunchTemplateVersions",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:RunInstances"
        ]
        Resource = ["arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:launch-template/*"]
        Condition = {
          StringEquals = { "aws:ResourceTag/UpwindComponent" = "CloudScanner" }
        }
      },
      # The following permissions are granted to allow the Auto Scaling group to perform a Dryrun to verify its configuration.
      {
        Sid    = "RunInstancesWithLaunchTemplate"
        Effect = "Allow"
        Action = ["ec2:RunInstances"]
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:network-interface/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:security-group/*",
          # Permit subnets from any account to be attached to the launch template. This is to facilitate subnets created
          # and shared from other accounts within the account using AWS Resource Access Management.
          "arn:${data.aws_partition.current.partition}:ec2:*:*:subnet/*",
          "arn:${data.aws_partition.current.partition}:ec2:*::image/ami-*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:volume/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:key-pair/*"
        ]
        Condition = {
          ArnLike = { "ec2:LaunchTemplate" = "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:launch-template/*" }
        }
      },
      # Permissions to Create Tags on resources only when creating Ec2 instances
      {
        Sid    = "CreateEC2ASGInstanceResourceTags"
        Effect = "Allow"
        Action = ["ec2:CreateTags"]
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:volume/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:network-interface/*"
        ]
        Condition = {
          StringEquals = {
            "aws:RequestTag/UpwindComponent" = "CloudScanner"
            "ec2:CreateAction"               = "RunInstances"
          }
        }
      },
      # Permissions to Create Security Groups
      {
        Sid    = "CreateSecurityGroupsWithTags"
        Effect = "Allow"
        Action = [
          "ec2:CreateTags",
          "ec2:CreateSecurityGroup"
        ]
        Resource = ["arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:security-group/*"]
        Condition = {
          StringEquals = { "aws:RequestTag/UpwindComponent" = "CloudScanner" }
        }
      },
      {
        Sid    = "CreateSecurityGroupsWithoutTags"
        Effect = "Allow"
        Action = ["ec2:CreateSecurityGroup"]
        Resource = [
          # Permit VPCs from any account to be attached to the launch template. This is to facilitate VPCs created
          # and shared from other accounts within the account using AWS Resource Access Management.
          "arn:${data.aws_partition.current.partition}:ec2:*:*:vpc/*"
        ]
      },
      # Permissions to Manage Security Groups
      {
        Sid    = "ManageSecurityGroups"
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteSecurityGroup",
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Resource = ["arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:security-group/*"]
        Condition = {
          StringEquals = { "aws:ResourceTag/UpwindComponent" = "CloudScanner" }
        }
      }
    ]
  })

  tags = merge(
    var.custom_tags,
    {
      "upwind:aws:Component"      = "Onboarding",
      "upwind:aws:ReleaseVersion" = local.upwind_version
  })
}

resource "aws_iam_role_policy_attachment" "attach_cloudscanner_ec2_access_policy" {
  count = var.apply_for_orchestrator_account && var.upwind_cloudscanner_management_enabled ? 1 : 0

  role       = aws_iam_role.account_service_role.name
  policy_arn = one(aws_iam_policy.account_service_cloudscanner_ec2_access_policy[*].arn)
}

resource "aws_iam_policy" "account_service_cloudscanner_ec2_network_permissions_access_policy" {
  # The CloudScanner EC2 access policy should only be created when also creating the the orchestration role.
  count       = var.apply_for_orchestrator_account && var.upwind_cloudscanner_management_enabled && var.upwind_include_ec2_network_management_permissions ? 1 : 0
  name        = var.account_service_cloudscanner_ec2_network_policy_name
  path        = (var.iam_role_path != "/") ? var.iam_role_path : null
  description = "Upwind Account Service IAM role policy to grant permissions to manage EC2 network resources."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Permissions to Create VPCs
      {
        Sid    = "CreateVPCs"
        Effect = "Allow"
        Action = [
          "ec2:CreateTags",
          "ec2:CreateVpc",
          "ec2:CreateVpcEndpoint"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:vpc/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:vpc-endpoint/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:route-table/*"
        ]
        Condition = {
          StringEquals = { "aws:RequestTag/UpwindComponent" = "CloudScanner" }
        }
      },
      # Permissions to Create VPC Endpoints are untagged. When creating VPC endpoints some resources are created
      # automatically without Tags - for example a default route-table. Unfortunately Cloudformation has no visibility
      # of these resources and does not apply the tags when creating these resources.
      # Note: The CreateVpcEndpoint does not create the VPC endpoint here.
      {
        Sid    = "CreateVPCEndpointsUntagged"
        Effect = "Allow"
        Action = ["ec2:CreateVpcEndpoint"]
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:vpc/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:route-table/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:subnet/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:security-group/*"
        ]
      },
      # Permissions to Manage VPCs
      {
        Sid    = "ManageVPCs"
        Effect = "Allow"
        Action = [
          "ec2:ModifyVpcAttribute",
          "ec2:ModifyVpcEndpoint",
          "ec2:DeleteVpc",
          "ec2:DeleteVpcEndpoints"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:vpc/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:vpc-endpoint/*"
        ]
        Condition = {
          StringEquals = { "aws:ResourceTag/UpwindComponent" = "CloudScanner" }
        }
      },
      # Permissions to Create NAT Gateway
      # ec2:CreateNatGateway requires access to several types of resources - some can be tagged,
      # while others can't
      {
        Sid    = "CreateNATGatewaysWithTag"
        Effect = "Allow"
        Action = [
          "ec2:CreateTags",
          "ec2:CreateNatGateway"
        ]
        Resource = ["arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:natgateway/*"]
        Condition = {
          StringEquals = { "aws:RequestTag/UpwindComponent" = "CloudScanner" }
        }
      },
      {
        Sid    = "CreateNATGatewaysWithoutTag"
        Effect = "Allow"
        Action = [
          "ec2:CreateTags",
          "ec2:CreateNatGateway"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:elastic-ip/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:subnet/*"
        ]
      },
      # Permissions to Remove NAT Gateway
      {
        Sid      = "DeleteNATGateways"
        Effect   = "Allow"
        Action   = ["ec2:DeleteNatGateway"]
        Resource = ["arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:natgateway/*"]
        Condition = {
          StringEquals = { "aws:ResourceTag/UpwindComponent" = "CloudScanner" }
        }
      },
      # Permissions to Create Internet Gateway
      {
        Sid    = "CreateInternetGateways"
        Effect = "Allow"
        Action = [
          "ec2:CreateTags",
          "ec2:CreateInternetGateway"
        ]
        Resource = ["arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:internet-gateway/*"]
        Condition = {
          StringEquals = { "aws:RequestTag/UpwindComponent" = "CloudScanner" }
        }
      },
      # Permissions to Manage Internet Gateway
      {
        Sid    = "ManageInternetGateways"
        Effect = "Allow"
        Action = [
          "ec2:AttachInternetGateway",
          "ec2:DetachInternetGateway",
          "ec2:DeleteInternetGateway"
        ]
        Resource = ["arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:internet-gateway/*"]
        Condition = {
          StringEquals = { "aws:ResourceTag/UpwindComponent" = "CloudScanner" }
        }
      },
      # Permission to Configure networking - subnets, routes etc.
      {
        Sid    = "NetworkConfigurationCreateWithTags"
        Effect = "Allow"
        Action = [
          "ec2:AllocateAddress",
          "ec2:CreateTags",
          "ec2:CreateRouteTable",
          "ec2:CreateSubnet"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:elastic-ip/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:route-table/*"
        ]
        Condition = {
          StringEquals = { "aws:RequestTag/UpwindComponent" = "CloudScanner" }
        }
      },
      {
        Sid    = "NetworkConfigurationCreateWithoutTags"
        Effect = "Allow"
        Action = [
          "ec2:CreateRoute",
          "ec2:CreateRouteTable",
          "ec2:CreateSubnet",
          "ec2:AttachInternetGateway"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:route-table/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:vpc/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:subnet/*"
        ]
      },
      {
        Sid    = "NetworkConfigurationDelete"
        Effect = "Allow"
        Action = [
          "ec2:AssociateRouteTable",
          "ec2:DeleteRoute",
          "ec2:DeleteRouteTable",
          "ec2:DeleteSubnet",
          "ec2:DisassociateRouteTable",
          "ec2:ModifySubnetAttribute",
          "ec2:ReleaseAddress",
          "ec2:DetachInternetGateway"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:elastic-ip/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:route-table/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:subnet/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:vpc/*"
        ]
        Condition = {
          StringEquals = { "aws:ResourceTag/UpwindComponent" = "CloudScanner" }
        }
      },
      # Policy which allows tags to be added/removed from the CloudScanner network resources.
      {
        Sid    = "ModifyTagsOnCloudscannerNetworkResources"
        Effect = "Allow"
        Action = [
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:internet-gateway/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:elastic-ip/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:route-table/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:subnet/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:vpc/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:natgateway/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:vpc-endpoint/*"
        ]
        Condition = {
          StringEquals = { "aws:ResourceTag/UpwindComponent" = "CloudScanner" }
        }
      }
    ]
  })

  tags = merge(
    var.custom_tags,
    {
      "upwind:aws:Component"      = "Onboarding",
      "upwind:aws:ReleaseVersion" = local.upwind_version
    }
  )
}

resource "aws_iam_role_policy_attachment" "attach_cloudscanner_ec2_network_permissions_access_policy" {
  count = var.apply_for_orchestrator_account && var.upwind_cloudscanner_management_enabled && var.upwind_include_ec2_network_management_permissions ? 1 : 0

  role       = aws_iam_role.account_service_role.name
  policy_arn = one(aws_iam_policy.account_service_cloudscanner_ec2_network_permissions_access_policy[*].arn)
}

resource "aws_iam_policy" "account_service_cloudscanner_access_policy" {
  # The CloudScanner access policy should only be created when also creating the the orchestration role.
  count       = var.apply_for_orchestrator_account && var.upwind_cloudscanner_management_enabled ? 1 : 0
  name        = var.account_service_cloudscanner_policy_name
  path        = (var.iam_role_path != "/") ? var.iam_role_path : null
  description = "Upwind Account Service IAM role policy to grant permissions to extra services used when managing CloudScanners."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # Permissions that allow the CloudScanner to create KMS keys.
      # This is a restricted list which does not adhere to the recommendations in
      # https://repost.aws/knowledge-center/update-key-policy-future as these introduce a significant number of roles. Instead the KMS
      # create should be created with the BypassPolicyLockoutSafetyCheck option and can have a policy with a reduced set of the roles.
      # Key creation/delete will be constrained to expect a specific tag which must also be added the KMS key when creating it.
      # See https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html for more details
      var.upwind_enable_self_managed_kms_key ? [] : [
        {
          Sid    = "RestrictedKMSCreateKey"
          Effect = "Allow"
          Action = [
            "kms:CreateKey",
            "kms:TagResource"
          ]
          Resource = [
            # CreateKey is rejected on any resource other than *.
            "*"
          ]
          Condition = {
            StringEquals = {
              "kms:CallerAccount"              = "${data.aws_caller_identity.current.account_id}"
              "kms:KeyUsage"                   = "ENCRYPT_DECRYPT"
              "kms:KeySpec"                    = "SYMMETRIC_DEFAULT"
              "aws:RequestTag/UpwindComponent" = "CloudScanner"
            }
          }
        }
      ],
      # Policy that allows tags to be added/removed from the CloudScanner KMS keys.
      var.upwind_enable_self_managed_kms_key ? [] : [
        {
          Sid    = "ModifyTagsOnCloudScannerKMSKey"
          Effect = "Allow"
          Action = [
            "kms:TagResource",
            "kms:UntagResource"
          ]
          Resource = [
            # CreateKey is rejected on any resource other than *.
            "arn:${data.aws_partition.current.partition}:kms:*:${data.aws_caller_identity.current.account_id}:key/*"
          ]
          Condition = {
            StringEquals = { "aws:ResourceTag/UpwindComponent" = "CloudScanner" }
          }
        }
      ],
      # Restrict Update key operations so that only the policy, description and rotation can be updated.
      var.upwind_enable_self_managed_kms_key ? [] : [
        {
          Sid    = "RestrictedKMSUpdateKey"
          Effect = "Allow"
          Action = [
            "kms:UpdateKeyDescription",
            "kms:PutKeyPolicy",
            "kms:EnableKeyRotation",
            "kms:DisableKeyRotation",
            "kms:GetKeyRotationStatus"
          ]
          Resource = ["arn:${data.aws_partition.current.partition}:kms:*:${data.aws_caller_identity.current.account_id}:key/*"]
          Condition = {
            StringEquals = { "aws:ResourceTag/UpwindComponent" = "CloudScanner" }
          }
        }
      ],
      var.upwind_enable_self_managed_kms_key ? [] : [
        {
          # Restrict KMS delete operations to only tagged keys.
          Sid      = "RestrictedKMSDelete"
          Effect   = "Allow"
          Action   = ["kms:ScheduleKeyDeletion"]
          Resource = ["arn:${data.aws_partition.current.partition}:kms:*:${data.aws_caller_identity.current.account_id}:key/*"]
          Condition = {
            StringEquals = {
              "kms:CallerAccount"               = "${data.aws_caller_identity.current.account_id}"
              "kms:KeyUsage"                    = "ENCRYPT_DECRYPT"
              "kms:KeySpec"                     = "SYMMETRIC_DEFAULT"
              "aws:ResourceTag/UpwindComponent" = "CloudScanner"
            }
          }
        }
      ],
      # There does not appear to be a way to restrict alias creation/deletion to keys with specific tags.
      # as a result we restricting the permissions to create resources in this account is the next best thing.
      # The key ids are auto generated, but the alias can have a definable prefix
      var.upwind_enable_self_managed_kms_key ? [] : [
        {
          Sid    = "RestrictedKMSAliases"
          Effect = "Allow"
          Action = [
            "kms:CreateAlias",
            "kms:DeleteAlias"
          ]
          Resource = [
            "arn:${data.aws_partition.current.partition}:kms:*:${data.aws_caller_identity.current.account_id}:alias/csca-key-*",
            "arn:${data.aws_partition.current.partition}:kms:*:${data.aws_caller_identity.current.account_id}:key/*"
          ]
        }
      ],
      [
        # Permissions to manage CloudWatch logs for monitoring and logging.
        {
          Sid    = "AccessLogs"
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:DeleteLogGroup",
            "logs:Describe*",
            "logs:GetLogEvents",
            "logs:PutLogEvents",
            "logs:PutRetentionPolicy",
            "logs:TagResource",
            "logs:UntagResource"
          ]
          Resource = [
            # Grant permissions to only create logs with the following paths. The full log group names are not known when
            # when creating the log groups.
            "arn:${data.aws_partition.current.partition}:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/system-logs/upwind-cs-ucsc-*",
            "arn:${data.aws_partition.current.partition}:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/upwind-cs-lambda-ucsc-*"
          ]
        },
        # Permissions to manage the Lambda function for the CloudScanners. The full function names are not known when
        # defining the roles.
        # The roles which can be used in lambda:AddPermission and lambda:RemovePermission are implicitly limited by the roles
        # permitted by the PassRole policy - AccessIAMPassCloudscannerRole.
        {
          Sid    = "ManageUpwindLambdas"
          Effect = "Allow"
          Action = [
            "lambda:CreateAlias",
            "lambda:CreateFunction",
            "lambda:DeleteAlias",
            "lambda:DeleteFunction",
            "lambda:GetFunction",
            "lambda:InvokeFunction",
            "lambda:List*",
            "lambda:TagResource",
            "lambda:UpdateFunctionConfiguration",
            "lambda:UpdateFunctionCode",
            "lambda:UntagResource",
            "lambda:AddPermission",
            "lambda:RemovePermission"
          ]
          Resource = [
            "arn:${data.aws_partition.current.partition}:lambda:*:${data.aws_caller_identity.current.account_id}:function:upwind-cs-lambda-ucsc-*",
            "arn:${data.aws_partition.current.partition}:lambda:*:${data.aws_caller_identity.current.account_id}:function:upwind-cs-ss-lambda-ucsc-*",
            "arn:${data.aws_partition.current.partition}:lambda:*:${data.aws_caller_identity.current.account_id}:function:upwind-cs-updater-ucsc-*",
            "arn:${data.aws_partition.current.partition}:lambda:*:${data.aws_caller_identity.current.account_id}:function:upwind-cs-dspm-rds-executor-ucsc-*"
          ]
        },
        # Permissions required to tag Event / Lambda trigger rules when creating
        {
          Sid    = "CloudScannerLambdaRulesTags"
          Effect = "Allow"
          Action = [
            "events:TagResource",
            "events:UntagResource"
          ]
          Resource = [
            "arn:${data.aws_partition.current.partition}:events:*:${data.aws_caller_identity.current.account_id}:rule/CloudScanner*",
            "arn:${data.aws_partition.current.partition}:events:*:${data.aws_caller_identity.current.account_id}:rule/upwind-cloud-scanner*"
          ]
          Condition = {
            StringEquals = { "aws:RequestTag/UpwindComponent" = "CloudScanner" }
          }
        },
        # Permissions required to modify tags post creation
        {
          Sid    = "CloudScannerLambdaRulesModifyTags"
          Effect = "Allow"
          Action = [
            "events:TagResource",
            "events:UntagResource"
          ]
          Resource = [
            "arn:${data.aws_partition.current.partition}:events:*:${data.aws_caller_identity.current.account_id}:rule/CloudScanner*",
            "arn:${data.aws_partition.current.partition}:events:*:${data.aws_caller_identity.current.account_id}:rule/upwind-cloud-scanner*"
          ]
          Condition = {
            StringEquals = { "aws:ResourceTag/UpwindComponent" = "CloudScanner" }
          }
        },
        {
          Effect = "Allow"
          # This policy goes hand in hand with the policy above and helps limits the source for the Lambdas to the
          # Upwind publishing bucket.
          Sid    = "AccessUpwindS3ServerlessBucket"
          Action = ["s3:GetObject"]
          Resource = [
            # S3 objects are limited to buckets and cannot include accounts ids.
            "arn:${data.aws_partition.current.partition}:s3:::upwind-serverless-functions-*/integrations/cloudscanner/*"
          ]
          Condition = {
            StringEquals = {
              # Restricting S3 Access to the Upwind publishing account
              "aws:ResourceAccount" = local.partition.publishing_account
            }
            "ForAnyValue:StringEquals" = {
              # Cloudformation URL is not partition
              "aws:CalledVia" = "cloudformation.amazonaws.com"
            }
          }
        },
        # Permissions to manage CloudWatch Events.
        {
          Sid    = "AccessCloudWatchEvents"
          Effect = "Allow"
          Action = [
            "events:DescribeRule",
            "events:PutRule",
            "events:PutTargets",
            "events:EnableRule",
            "events:DisableRule",
            "events:DeleteRule",
            "events:RemoveTargets"
          ]
          Resource = [
            "arn:${data.aws_partition.current.partition}:events:*:${data.aws_caller_identity.current.account_id}:rule/CloudScanner*",
            "arn:${data.aws_partition.current.partition}:events:*:${data.aws_caller_identity.current.account_id}:rule/upwind-cloud-scanner*"
          ]
        },
        # Permissions to pass the CloudScanner Admin role to the necessary resources and services
        # The Account Service role can be used to update the CloudScanner stack configuration. This includes applying configuration
        # changes to the ASG and launch templates. In order to do so, the role needs to pass the CloudScanner Admin role to the
        # necessary services.
        # This is effectively delegating permissions to the AWS services (Auto Scaling Group and EC2 services) to perform the
        # actions on the resources on our behalf
        # The role here must match the role configured in the instance policy associated with the ASG, otherwise it does not
        # appear to be assumed.
        {
          Sid      = "AccessIAMPassCloudscannerRole"
          Effect   = "Allow"
          Action   = ["iam:PassRole"]
          Resource = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role${var.iam_role_path}${var.cloudscanner_admin_role_name}"
          Condition = {
            StringEquals = {
              "iam:PassedToService" = [
                "ec2.amazonaws.com",
                "lambda.amazonaws.com"
              ]
            }
          }
        },
        # Permission to allow the creation of the AWSServiceRoleForAutoScaling role which
        # AWS may need to create automatically when creating the fist ASG if the role does not
        # already exist.
        {
          Sid      = "AutoscalingServiceLinkedRoleCreatePolicy"
          Effect   = "Allow"
          Action   = ["iam:CreateServiceLinkedRole"]
          Resource = ["arn:${data.aws_partition.current.partition}:iam::*:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling*"]
          Condition = {
            StringLike = { "iam:AWSServiceName" = "autoscaling.amazonaws.com" }
          }
        },
        # DSPM RDS: allow the account service role to create the tagged DB subnet group the CloudScanner
        # stack provisions for DSPM RDS scan copies. Needed for stack create; mirrors the delete grant below.
        # AddTagsToResource is required because RDS tags the subnet group at create time.
        {
          Sid    = "CreateCloudScannerDspmRdsSubnetGroup"
          Effect = "Allow"
          Action = [
            "rds:CreateDBSubnetGroup",
            "rds:AddTagsToResource"
          ]
          Resource = ["arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:subgrp:upwind-cs-dspm-rds-*"]
          Condition = {
            StringEquals = { "aws:RequestTag/UpwindComponent" = "CloudScanner" }
          }
        },
        # DSPM RDS: allow deletion of the DB subnet group that the CloudScanner stack creates for DSPM RDS scan
        # copies. The account service role drives CloudFormation stack teardown, so it must be able to delete
        # this stack-owned resource; without it, scanner-stack deletion fails on the subnet group. The subnet
        # group is tagged UpwindComponent=CloudScanner by the CloudScanner stack.
        {
          Sid      = "DeleteCloudScannerDspmRdsSubnetGroup"
          Effect   = "Allow"
          Action   = ["rds:DeleteDBSubnetGroup"]
          Resource = ["arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:subgrp:upwind-cs-dspm-rds-*"]
          Condition = {
            StringEquals = { "aws:ResourceTag/UpwindComponent" = "CloudScanner" }
          }
        }
      ],
      # DSPM RDS: allow the account service role to remove the scan databases, and only those. They are
      # created by the executor lambda at runtime, so they are not CloudFormation resources: the stack delete
      # neither removes them nor waits for them, and while they run their network interfaces hold the stack's
      # DB subnet group, security group, subnets and VPC, so the delete fails.
      #
      # The name pattern is the full shape the state machine's ResourceNamer produces,
      # cloudscanner-dspm-<stage>-<source>-<rowId>, where the row id always carries the ucsds- prefix, so a
      # database has to be one it created for a specific scan row. The component tag is required on top of
      # that, mirroring the ownership test in the teardown code, which also requires both. A customer
      # database sitting in the same subnet group satisfies none of it.
      #
      # The describes the teardown also needs come from the SecurityAudit managed policy attached to this
      # role above, which grants rds:Describe*.
      (local.orchestrator_account_id != "" && local.dspm_rds_enabled) ? [
        {
          Sid    = "DeleteCloudScannerDspmRdsDatabases"
          Effect = "Allow"
          Action = [
            "rds:DeleteDBInstance",
            "rds:DeleteDBCluster"
          ]
          Resource = [
            "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:db:cloudscanner-dspm-*-ucsds-*",
            "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:cluster:cloudscanner-dspm-*-ucsds-*"
          ]
          Condition = {
            StringEquals = { "aws:ResourceTag/UpwindComponent" = "CloudScanner" }
          }
        }
      ] : []
    )
  })

  tags = merge(
    var.custom_tags,
    {
      "upwind:aws:Component"      = "Onboarding",
      "upwind:aws:ReleaseVersion" = local.upwind_version
    }
  )
}

resource "aws_iam_role_policy_attachment" "attach_cloudscanner_access_policy" {
  count = var.apply_for_orchestrator_account && var.upwind_cloudscanner_management_enabled ? 1 : 0

  role       = aws_iam_role.account_service_role.name
  policy_arn = one(aws_iam_policy.account_service_cloudscanner_access_policy[*].arn)
}

resource "aws_iam_policy" "account_service_agentless_k8s_access_entries_access_policy" {
  count       = local.agentless_k8s_access_entries_enabled ? 1 : 0
  name        = var.account_service_agentless_k8s_access_entries_policy_name
  path        = (var.iam_role_path != "/") ? var.iam_role_path : null
  description = "Upwind Account Service IAM role policy for agentless Kubernetes resource fetching using EKS access entries as the authentication method."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Determine cluster endpoint, CA data, if cluster is public or private
      {
        Sid      = "DescribeCluster"
        Effect   = "Allow"
        Action   = ["eks:DescribeCluster"]
        Resource = "arn:${data.aws_partition.current.partition}:eks:*:${data.aws_caller_identity.current.account_id}:cluster/*"
      },
      # Create access entry for the Upwind account service role
      # Access entry must have a upwind:aws:CreatedByUpwind=true tag
      {
        Sid      = "SelfProvisionAccessEntry"
        Effect   = "Allow"
        Action   = ["eks:CreateAccessEntry"]
        Resource = "arn:${data.aws_partition.current.partition}:eks:*:${data.aws_caller_identity.current.account_id}:cluster/*"
        Condition = {
          StringEquals = {
            "eks:principalArn"                          = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role${var.iam_role_path}${var.account_service_role_name}"
            "aws:RequestTag/upwind:aws:CreatedByUpwind" = "true"
          }
        }
      },
      # Describe Upwind access entries
      {
        Sid      = "DescribeAccessEntry"
        Effect   = "Allow"
        Action   = ["eks:DescribeAccessEntry"]
        Resource = "arn:${data.aws_partition.current.partition}:eks:*:${data.aws_caller_identity.current.account_id}:access-entry/*/role/${data.aws_caller_identity.current.account_id}${var.iam_role_path}${var.account_service_role_name}/*"
      },
      # List associated access policies for Upwind access entries
      {
        Sid      = "ListAssociatedAccessPolicies"
        Effect   = "Allow"
        Action   = ["eks:ListAssociatedAccessPolicies"]
        Resource = "arn:${data.aws_partition.current.partition}:eks:*:${data.aws_caller_identity.current.account_id}:access-entry/*/role/${data.aws_caller_identity.current.account_id}${var.iam_role_path}${var.account_service_role_name}/*"
      },
      # Allow setting upwind:aws:CreatedByUpwind=true tag on Upwind access entries
      {
        Sid      = "AllowTaggingOnCreation"
        Effect   = "Allow"
        Action   = ["eks:TagResource"]
        Resource = "arn:${data.aws_partition.current.partition}:eks:*:${data.aws_caller_identity.current.account_id}:access-entry/*/role/${data.aws_caller_identity.current.account_id}${var.iam_role_path}${var.account_service_role_name}/*"
        Condition = {
          StringEquals = { "aws:RequestTag/upwind:aws:CreatedByUpwind" = "true" }
        }
      },
      # Allow associating AmazonEKSViewPolicy and AmazonEKSAdminViewPolicy to Upwind access entries.
      {
        Sid      = "AssociateViewOnlyPolicy"
        Effect   = "Allow"
        Action   = ["eks:AssociateAccessPolicy"]
        Resource = "arn:${data.aws_partition.current.partition}:eks:*:${data.aws_caller_identity.current.account_id}:access-entry/*/role/${data.aws_caller_identity.current.account_id}${var.iam_role_path}${var.account_service_role_name}/*"
        Condition = {
          StringEquals = {
            "eks:policyArn" = var.upwind_agentless_k8s_eks_admin_view_policy_enabled ? [
              "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSViewPolicy",
              "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSAdminViewPolicy"
            ] : ["arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"]
            "eks:principalArn" = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role${var.iam_role_path}${var.account_service_role_name}"
          }
        }
      },
      # Delete access entry and disassociate access policy for Upwind access entries
      {
        Sid    = "CleanupSelfCreatedEntries"
        Effect = "Allow"
        Action = [
          "eks:DeleteAccessEntry",
          "eks:DisassociateAccessPolicy"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:eks:*:${data.aws_caller_identity.current.account_id}:access-entry/*/role/${data.aws_caller_identity.current.account_id}${var.iam_role_path}${var.account_service_role_name}/*"
        Condition = {
          StringEquals = { "aws:ResourceTag/upwind:aws:CreatedByUpwind" = "true" }
        }
      }
    ]
  })

  tags = merge(
    var.custom_tags,
    {
      "upwind:aws:Component"      = "Onboarding",
      "upwind:aws:ReleaseVersion" = local.upwind_version
    }
  )
}

resource "aws_iam_role_policy_attachment" "attach_agentless_k8s_access_entries_access_policy" {
  count = local.agentless_k8s_access_entries_enabled ? 1 : 0

  role       = aws_iam_role.account_service_role.name
  policy_arn = one(aws_iam_policy.account_service_agentless_k8s_access_entries_access_policy[*].arn)
}

resource "aws_iam_policy" "account_service_agentless_k8s_ssm_access_policy" {
  count       = local.agentless_k8s_ssm_enabled ? 1 : 0
  name        = var.account_service_agentless_k8s_ssm_policy_name
  path        = (var.iam_role_path != "/") ? var.iam_role_path : null
  description = "Upwind Account Service IAM role policy for agentless Kubernetes resource fetching from private EKS clusters via SSM tunnels."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Determine cluster endpoint, CA data, if cluster is public or private
      {
        Sid      = "DescribeCluster"
        Effect   = "Allow"
        Action   = ["eks:DescribeCluster"]
        Resource = "arn:${data.aws_partition.current.partition}:eks:*:${data.aws_caller_identity.current.account_id}:cluster/*"
      },
      # Used to find potential SSM targets (cluster instances, instances in the cluster security group).
      {
        Sid      = "EC2DescribeInstances"
        Effect   = "Allow"
        Action   = "ec2:DescribeInstances"
        Resource = "*"
      },
      # Used to query SSM for node status, to find available SSM targets.
      {
        Sid      = "SSMDescribeInstanceInformation"
        Effect   = "Allow"
        Action   = "ssm:DescribeInstanceInformation"
        Resource = "*"
      },
      # Permission to start an SSM session. Allowed on all instances in the account, further scoped by the
      # following Deny statement, and restricted to the StartPortForwardingSessionToRemoteHost document.
      {
        Sid    = "SSMStartSession"
        Effect = "Allow"
        Action = "ssm:StartSession"
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*",
          "arn:${data.aws_partition.current.partition}:ssm:*:*:document/AWS-StartPortForwardingSessionToRemoteHost"
        ]
        Condition = {
          BoolIfExists = { "ssm:SessionDocumentAccessCheck" = "true" }
        }
      },
      # Only allow SSM StartSession on nodes that are part of an EKS cluster
      # or have the upwind:ssm-target tag.
      {
        Sid      = "DenySSMStartSession"
        Effect   = "Deny"
        Action   = "ssm:StartSession"
        Resource = "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*"
        Condition = {
          Null = {
            "aws:ResourceTag/aws:eks:cluster-name" = "true"
            "aws:ResourceTag/eks:cluster-name"     = "true"
            "aws:ResourceTag/upwind:ssm-target"    = "true"
          }
        }
      },
      # Allow session management on Upwind sessions
      {
        Sid    = "SSMSessionManagement"
        Effect = "Allow"
        Action = [
          "ssm:TerminateSession",
          "ssm:ResumeSession"
        ]
        Resource = ["arn:${data.aws_partition.current.partition}:ssm:*:${data.aws_caller_identity.current.account_id}:session/upwind*"]
      }
    ]
  })

  tags = merge(
    var.custom_tags,
    {
      "upwind:aws:Component"      = "Onboarding",
      "upwind:aws:ReleaseVersion" = local.upwind_version
    }
  )
}

resource "aws_iam_role_policy_attachment" "attach_agentless_k8s_ssm_access_policy" {
  count = local.agentless_k8s_ssm_enabled ? 1 : 0

  role       = aws_iam_role.account_service_role.name
  policy_arn = one(aws_iam_policy.account_service_agentless_k8s_ssm_access_policy[*].arn)
}

resource "aws_iam_role_policy" "securityhub_integration" {
  count = var.enable_securityhub_integration ? 1 : 0
  name  = "SecurityHubFindingsImportPolicy"
  role  = aws_iam_role.account_service_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ImportFindingsToSecurityHub"
        Effect   = "Allow"
        Action   = ["securityhub:BatchImportFindings"]
        Resource = "*"
      }
    ]
  })
}

# Reads the onboarding settings parameter that is written in each orchestrator account.
resource "aws_iam_role_policy" "account_service_onboarding_configuration" {
  count = local.is_orchestrator_account ? 1 : 0
  name  = "UpwindOnboardingConfigurationReadPolicy"
  role  = aws_iam_role.account_service_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadUpwindOnboardingConfiguration"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${local.ssm_parameter_prefix}",
          "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${local.ssm_parameter_prefix}/*"
        ]
      }
    ]
  })
}
