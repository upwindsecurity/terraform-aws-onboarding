data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "account_service_role" {
  name        = var.account_service_role_name
  description = "Grants Upwind Security the necessary permissions to oversee and manage account-level governance, including security audits, compliance checks, and operational control."
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Principal = {
            AWS = [
              var.trusted_arn
            ]
          }
          Action = "sts:AssumeRole"
          Condition = {
            "StringEquals" = {
              "sts:ExternalId" = var.external_id
            }
          }
        }
      ]
    }
  )

  # The Upwind backend uses tags on the roles for system discovery. These tags must not be altered.
  tags = merge(
    var.custom_tags,
    {
      "upwind:aws:Component"      = "Onboarding",
      "upwind:aws:ReleaseVersion" = local.upwind_version
    },
    # If the role is being created with elevated permissions, we will add the additional tags needed for
    # CloudScanner Discovery
    var.apply_for_orchestrator_account ? {
      "upwind:aws:CloudScannerAdministrationRoleName" = var.cloudscanner_admin_role_name
      "upwind:aws:CloudScannerExecutionRoleName"      = var.cloudscanner_execution_role_name
      "upwind:aws:CloudScannerInstallRegion"          = data.aws_region.current.region
      "upwind:aws:CloudScannerSecretARN"              = var.cloudscanner_secret_arn
      "upwind:aws:HasDSPMPermissions"                 = var.upwind_feature_dspm_enabled ? "Yes" : "No"
      "upwind:aws:HasCSAutomationPermissions"         = var.upwind_cloudscanner_management_enabled ? "Yes" : "No"
      "upwind:aws:HasCSEC2NetworkPermissions"         = var.upwind_include_ec2_network_management_permissions ? "Yes" : "No"
    } : {},
  )
}

resource "aws_iam_role_policy_attachment" "account_service_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
  role       = aws_iam_role.account_service_role.name
}

resource "aws_iam_role_policy" "account_service_view_access_policy" {
  name = "ViewAccessPolicy"
  role = aws_iam_role.account_service_role.name

  policy = jsonencode(
    {
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
          Sid    = "AccessBedrock"
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
          Sid    = "AccessAmazonQ"
          Effect = "Allow"
          Action = [
            "qbusiness:ListApplications",
            "qbusiness:GetApplication"
          ]
          Resource = "*"
        },
        {
          Sid    = "AccessSagemaker"
          Effect = "Allow"
          Action = [
            "sagemaker:ListEndpoints",
            "sagemaker:DescribeEndpoint",
            "sagemaker:ListEndpointConfigs",
            "sagemaker:DescribeEndpointConfig",
            "sagemaker:ListModels",
            "sagemaker:DescribeModel"
          ]
          Resource = "*"
        },
        {
          Sid    = "AccessLexmodels"
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
          Sid    = "AccessRekognition"
          Effect = "Allow"
          Action = [
            "rekognition:ListStreamProcessors",
            "rekognition:DescribeStreamProcessor"
          ]
          Resource = "*"
        },
        {
          Sid    = "AccessComprehend"
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
          Sid    = "AccessAppSync"
          Effect = "Allow"
          Action = [
            "appsync:ListGraphqlApis",
            "appsync:GetGraphqlApi"
          ]
          Resource = "*"
        },
        {
          Sid    = "AccessPricing"
          Effect = "Allow"
          Action = [
            "pricing:GetProducts"
          ]
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
          Sid    = "AccessAccount"
          Effect = "Allow"
          Action = [
            "account:GetContactInformation"
          ]
          Resource = "*"
        },
        {
          Sid    = "AccessSecurityHub"
          Effect = "Allow"
          Action = [
            "securityhub:BatchImportFindings"
          ]
          Resource = "*"
        },
        {
          Sid    = "AccessIdentityStoreAuth"
          Effect = "Allow"
          Action = [
            "identitystore-auth:BatchGetSession",
            "identitystore-auth:ListSessions"
          ]
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
          Sid    = "AccessAirflow"
          Effect = "Allow"
          Action = [
            "airflow:GetEnvironment"
          ]
          Resource = "*"
        },
        {
          Sid    = "AccessLogs"
          Effect = "Allow"
          Action = [
            "logs:GetLogEvents"
          ]
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
          Sid    = "AccessAppFlow"
          Effect = "Allow"
          Action = [
            "appflow:DescribeFlow"
          ]
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
          Sid    = "AccessStates"
          Effect = "Allow"
          Action = [
            "states:ListTagsForResource"
          ]
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
          Sid    = "AccessWAF"
          Effect = "Allow"
          Action = [
            "waf:GetLoggingConfiguration"
          ]
          Resource = "*"
        },
        {
          Sid    = "AccessWAFv2"
          Effect = "Allow"
          Action = [
            "wafv2:GetLoggingConfiguration"
          ]
          Resource = "*"
        },
        {
          Sid    = "AccessWAFRegional"
          Effect = "Allow"
          Action = [
            "waf-regional:GetLoggingConfiguration"
          ]
          Resource = "*"
        },
        {
          Sid    = "AccessDS"
          Effect = "Allow"
          Action = [
            "ds:ListTagsForResource"
          ]
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
          Sid    = "AccessGlacier"
          Effect = "Allow"
          Action = [
            "glacier:ListTagsForVault"
          ]
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
    }
  )
}

resource "aws_iam_policy" "account_service_cloudformation_access_policy" {
  # The Cloudformation access policy should only be created when also creating the the orchestration role.
  count       = var.apply_for_orchestrator_account && var.upwind_cloudscanner_management_enabled ? 1 : 0
  name        = var.account_service_cloudformation_policy_name
  description = "Upwind Account Service IAM role policy for using Cloudformation to manage CloudScanners."

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          # Access to the ChangeSet is necessary to apply updates when using Cloudformation UpdateStack
          Sid    = "UpwindCloudformationChangeSet"
          Effect = "Allow"
          Action = [
            "cloudformation:CreateChangeSet"
          ]
          Resource = [
            "arn:aws:cloudformation:*:aws:transform/Serverless-2016-10-31"
          ]
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
            "arn:aws:cloudformation:*:${data.aws_caller_identity.current.account_id}:stack/upwind*",
            "arn:aws:cloudformation:*:${data.aws_caller_identity.current.account_id}:stack/Upwind*"
          ]
        },
        {
          Sid = "UpwindCloudformationCreateUpdateStackWithUrl"
          # Permissions which grant access to create and update stacks where,
          # a) the name is prefixed with Upwind/upwind
          # b) are created the whitelisted template Urls
          Effect = "Allow"
          Action = [
            "cloudformation:CreateStack",
            "cloudformation:UpdateStack"
          ]
          Resource = [
            "arn:aws:cloudformation:*:${data.aws_caller_identity.current.account_id}:stack/upwind*",
            "arn:aws:cloudformation:*:${data.aws_caller_identity.current.account_id}:stack/Upwind*"
          ]
          Condition = {
            StringLike = {
              "cloudformation:TemplateUrl" = local.upwind_cfn_sources
            }
          }
        },
        {
          Sid = "UpwindCloudformationCreateUpdateStackWithoutUrl"
          # Permit only the Upwind stacks to be updated, but with the condition that the template cannot be changed
          # This is necessary to permit changes to be applied to the stack configuration without applying a new version of the template
          Effect = "Allow"
          Action = [
            "cloudformation:UpdateStack"
          ]
          Resource = [
            "arn:aws:cloudformation:*:${data.aws_caller_identity.current.account_id}:stack/upwind*",
            "arn:aws:cloudformation:*:${data.aws_caller_identity.current.account_id}:stack/Upwind*"
          ]
          Condition = {
            # The null condition needs to be handled as a string, unlike the other conditions
            # This condition asserts that the TemplateUrl must not be supplied for the permission to be granted
            Null = {
              "cloudformation:TemplateUrl" = "true"
            }
          }
        }
      ]
    }
  )
  tags = merge(
    var.custom_tags,
    {
      "upwind:aws:Component"      = "Onboarding",
      "upwind:aws:ReleaseVersion" = local.upwind_version
  })
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
  description = "Upwind Account Service IAM role policy to grant permissions to EC2 services used when managing CloudScanners."

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Sid = "CreateASGs"
          # Permissions to Create Auto Scaling Groups
          Effect = "Allow"
          Action = [
            "ec2:CreateTags",
            "autoscaling:CreateAutoScalingGroup",
            "autoscaling:CreateLaunchConfiguration"
          ],
          Resource = [
            "arn:aws:autoscaling:*:${data.aws_caller_identity.current.account_id}:autoScalingGroup*:autoScalingGroupName/upwind-cs-asg*"
          ],
          Condition = {
            StringEquals = {
              "autoscaling:ResourceTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid = "ManageASGs"
          # Permissions to Manage Auto Scaling Groups
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
          Resource = [
            "arn:aws:autoscaling:*:${data.aws_caller_identity.current.account_id}:autoScalingGroup*:autoScalingGroupName/upwind-cs-asg*"
          ]
          Condition = {
            StringEquals = {
              "autoscaling:ResourceTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid = "DeleteASGs"
          # Permissions to Remove Auto Scaling Groups
          Effect = "Allow",
          Action = [
            "autoscaling:DeleteAutoScalingGroup",
            "autoscaling:DeleteLaunchConfiguration"
          ]
          Resource = [
            "arn:aws:autoscaling:*:${data.aws_caller_identity.current.account_id}:autoScalingGroup*:autoScalingGroupName/upwind-cs-asg*"
          ]
          Condition = {
            StringEquals = {
              "autoscaling:ResourceTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid = "CreateLaunchTemplates"
          # Permissions to Create Launch Templates
          Effect = "Allow"
          Action = [
            "ec2:CreateTags",
            "ec2:CreateLaunchTemplate",
            "ec2:CreateLaunchTemplateVersion"
          ]
          Resource = [
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:launch-template/*"
          ]
          Condition = {
            StringEquals = {
              "aws:RequestTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid = "ManageLaunchTemplates"
          # Permissions to Manage Launch Templates
          Effect = "Allow"
          Action = [
            "ec2:CreateLaunchTemplateVersion",
            "ec2:ModifyLaunchTemplate",
            "ec2:DeleteLaunchTemplate",
            "ec2:DeleteLaunchTemplateVersions",
            "ec2:DescribeLaunchTemplateVersions",
            "ec2:RunInstances"
          ]
          Resource = [
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:launch-template/*"
          ]
          Condition = {
            StringEquals = {
              "aws:ResourceTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid = "RunInstancesWithLaunchTemplate"
          # The following permissions are granted to allow the Auto Scaling group to perform a Dryrun to verify its configuration.
          Effect = "Allow"
          Action = [
            "ec2:RunInstances"
          ]
          Resource = [
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*",
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:network-interface/*",
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:security-group/*",
            # Permit subnets from any account to be attached to the launch template. This is to facilitate subnets created
            # and shared from other accounts using AWS Resource Access Management.
            "arn:aws:ec2:*:*:subnet/*",
            "arn:aws:ec2:*::image/ami-*",
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:volume/*",
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:key-pair/*"
          ]
          Condition = {
            ArnLike = {
              "ec2:LaunchTemplate" = "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:launch-template/*"
            }
          }
        },
        {
          Sid = "CreateEC2ASGInstanceResourceTags"
          # Permissions to Create Tags on resources only when creating Ec2 instances
          Effect = "Allow"
          Action = [
            "ec2:CreateTags"
          ]
          Resource = [
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*",
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:volume/*",
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:network-interface/*"
          ]
          Condition = {
            StringEquals = {
              "aws:RequestTag/UpwindComponent" = "CloudScanner",
              "ec2:CreateAction"               = "RunInstances"
            }
          }
        },
        {
          Sid = "CreateSecurityGroupsWith"
          # Permissions to Create Security Groups
          Effect = "Allow"
          Action = [
            "ec2:CreateTags",
            "ec2:CreateSecurityGroup"
          ]
          Resource = [
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:security-group/*"
          ]
          Condition = {
            StringEquals = {
              "aws:RequestTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid    = "CreateSecurityGroupsWithoutTags"
          Effect = "Allow"
          Action = [
            "ec2:CreateSecurityGroup"
          ]
          Resource = [
            # Permit VPCs from any account to be attached to the launch template. This is to facilitate VPCs created
            # and shared from other accounts within the account using AWS Resource Access Management.
            "arn:aws:ec2:*:*:vpc/*"

          ]
        },
        {
          Sid = "ManageSecurityGroups"
          # Permissions to Manage Security Groups
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
          Resource = [
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:security-group/*"
          ]
          Condition = {
            StringEquals = {
              "aws:ResourceTag/UpwindComponent" = "CloudScanner"
            }
          }
        }
      ]
    }
  )

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
  description = "Upwind Account Service IAM role policy to grant permissions to manage EC2 network resources."

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Sid = "CreateVPCs"
          # Permissions to Create VPCs
          Effect = "Allow"
          Action = [
            "ec2:CreateTags",
            "ec2:CreateVpc",
            "ec2:CreateVpcEndpoint"
          ]
          Resource = [
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:vpc/*",
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:vpc-endpoint/*",
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:route-table/*"
          ]
          Condition = {
            StringEquals = {
              "aws:RequestTag/UpwindComponent" = "CloudScanner"
            }
          },
        },
        {
          Sid = "CreateVPCEndpointsUntagged"
          # Permissions to Create VPC Endpoints are untagged. When creating VPC endpoints some resources are created
          # automatically without Tags - for example a default route-table. Unfortunately Cloudformation has no visibility
          # of these resources and does not apply the tags when creating these resources.
          # Note: The CreateVpcEndpoint does not create the VPC endpoint here.
          Effect = "Allow"
          Action = [
            "ec2:CreateVpcEndpoint"
          ]
          Resource = [
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:vpc/*",
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:route-table/*"
          ]
        },
        {
          Sid = "ManageVPCs"
          # Permissions to Manage VPCs
          Effect = "Allow",
          Action = [
            "ec2:ModifyVpcAttribute",
            "ec2:ModifyVpcEndpoint",
            "ec2:DeleteVpc",
            "ec2:DeleteVpcEndpoints"
          ]
          Resource = [
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:vpc/*",
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:vpc-endpoint/*"
          ]
          Condition = {
            StringEquals = {
              "aws:ResourceTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid = "CreateNATGatewaysWithTag"
          # Permissions to Create NAT Gateway
          # ec2:CreateNatGateway requires access to several types of resources - some can be tagged,
          # while others can't
          Effect = "Allow"
          Action = [
            "ec2:CreateTags",
            "ec2:CreateNatGateway"
          ]
          Resource = [
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:natgateway/*"
          ]
          Condition = {
            StringEquals = {
              "aws:RequestTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid = "CreateNATGatewayComponentsWithoutTag"

          Effect = "Allow"
          Action = [
            "ec2:CreateTags",
            "ec2:CreateNatGateway"
          ]
          Resource = [
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:elastic-ip/*",
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:subnet/*"
          ]
        },
        {
          Sid = "DeleteNATGateways"
          # Permissions to Remove NAT Gateway
          Effect = "Allow"
          Action = [
            "ec2:DeleteNatGateway"
          ]
          Resource = [
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:natgateway/*"
          ]
          Condition = {
            StringEquals = {
              "aws:ResourceTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid = "CreateInternetGateways"
          # Permissions to Create Internet Gateway
          Effect = "Allow"
          Action = [
            "ec2:CreateTags",
            "ec2:CreateInternetGateway"
          ]
          Resource = [
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:internet-gateway/*"
          ]
          Condition = {
            StringEquals = {
              "aws:RequestTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid = "ManageInternetGateways"
          # Permissions to Manage Internet Gateway
          Effect = "Allow"
          Action = [
            "ec2:AttachInternetGateway",
            "ec2:DetachInternetGateway",
            "ec2:DeleteInternetGateway"
          ]
          Resource = [
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:internet-gateway/*"
          ]
          Condition = {
            StringEquals = {
              "aws:ResourceTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid = "NetworkConfigurationCreateWithTags"
          # Permission to Configure networking - subnets, routes etc.
          Effect = "Allow"
          Action = [
            "ec2:AllocateAddress",
            "ec2:CreateTags",
            "ec2:CreateRouteTable",
            "ec2:CreateSubnet"
          ]
          Resource = [
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:elastic-ip/*",
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:route-table/*"
          ]
          Condition = {
            StringEquals = {
              "aws:RequestTag/UpwindComponent" = "CloudScanner"
            }
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
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:route-table/*",
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:vpc/*",
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:subnet/*"
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
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:elastic-ip/*",
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:route-table/*",
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:subnet/*",
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:vpc/*"
          ]
          Condition = {
            StringEquals = {
              "aws:ResourceTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid = "ModifyTagsOnCloudscannerNetworkResources"
          # Policy which allows tags to be added/removed from the CloudScanner network resources.
          Effect = "Allow"
          Action = [
            "ec2:CreateTags",
            "ec2:DeleteTags"
          ]
          Resource = [
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:internet-gateway/*",
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:elastic-ip/*",
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:route-table/*",
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:subnet/*",
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:vpc/*",
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:natgateway/*",
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:vpc-endpoint/*"
          ]
          Condition = {
            StringEquals = {
              "aws:ResourceTag/UpwindComponent" = "CloudScanner"
            }
          }
        }
      ]
    }
  )

  tags = merge(
    var.custom_tags,
    {
      "upwind:aws:Component"      = "Onboarding",
      "upwind:aws:ReleaseVersion" = local.upwind_version
  })
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
  description = "Upwind Account Service IAM role policy to grant permissions to extra services used when managing CloudScanners."

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Sid = "RestrictedKMSCreateKey"
          # Permissions that allow the CloudScanner to create KMS keys.
          # This is a restricted list which does not adhere to the recommendations in
          # https://repost.aws/knowledge-center/update-key-policy-future as these introduce a significant number of roles. Instead the KMS
          # create should be created with the BypassPolicyLockoutSafetyCheck option and can have a policy with a reduced set of the roles.
          # Key creation/delete will be constrained to expect a specific tag which must also be added the KMS key when creating it.
          # See https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html for more details

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
              "kms:CallerAccount"              = data.aws_caller_identity.current.account_id
              "kms:KeyUsage"                   = "ENCRYPT_DECRYPT"
              "kms:KeySpec"                    = "SYMMETRIC_DEFAULT"
              "aws:RequestTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid = "ModifyTagsOnCloudScannerKMSKey"
          # Policy that allows tags to be added/removed from the CloudScanner KMS keys.
          Effect = "Allow"
          Action = [
            "kms:TagResource",
            "kms:UntagResource"
          ]
          Resource = [
            "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:key/*"
          ]
          Condition = {
            StringEquals = {
              "aws:ResourceTag/UpwindComponent" : "CloudScanner"
            }
          }
        },
        {
          Sid = "RestrictedKMSUpdateKey"
          # Restrict Update key operations so that only the policy and descriptions can be updated.
          Effect = "Allow"
          Action = [
            "kms:UpdateKeyDescription",
            "kms:PutKeyPolicy"
          ]
          Resource = [
            "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:key/*"
          ]
          Condition = {
            StringEquals = {
              "aws:ResourceTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid = "RestrictedKMSDelete"
          # Restrict KMS delete operations to only tagged keys.
          Effect = "Allow"
          Action = [
            "kms:ScheduleKeyDeletion"
          ]
          Resource = [
            "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:key/*"
          ]
          Condition = {
            StringEquals = {
              "kms:CallerAccount"               = data.aws_caller_identity.current.account_id
              "kms:KeyUsage"                    = "ENCRYPT_DECRYPT"
              "kms:KeySpec"                     = "SYMMETRIC_DEFAULT"
              "aws:ResourceTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid = "RestrictedKMSAliases"
          # There does not appear to be a way to restrict alias creation/deletion to keys with specific tags.
          # as a result we restricting the permissions to create resources in this account is the next best thing.
          # The key ids are auto generated, but the alias can have a definable prefix
          Effect = "Allow"
          Action = [
            "kms:CreateAlias",
            "kms:DeleteAlias"
          ]
          Resource = [
            "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:alias/csca-key-*",
            "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:key/*"
          ]
        },
        {
          Sid = "AccessLogs"
          # Permissions to manage CloudWatch logs for monitoring and logging.
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
          # Grant permissions to only create logs with the following paths. The full log group names are not known when
          # when creating the log groups.
          Resource = [
            "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/system-logs/upwind-cs-ucsc-*",
            "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/upwind-cs-lambda-ucsc-*"
          ]
        },
        {
          Sid = "ManageUpwindLambdas"
          # Permissions to manage the Lambda function for the CloudScanners. The full function names are not known when
          # defining the roles.
          # The roles which can be used in lambda:AddPermission and lambda:RemovePermission are implicitly limited by the roles
          # permitted by the PassRole policy - AccessIAMPassCloudscannerRole.
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
            "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:upwind-cs-lambda-ucsc-*",
            "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:upwind-cs-ss-lambda-ucsc-*",
            "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:upwind-cs-updater-ucsc-*"
          ]
        },
        {
          Sid = "CloudScannerLambdaRulesTags"
          # Permissions required to tag Event / Lambda trigger rules
          Effect = "Allow"
          Action = [
            "events:TagResource",
            "events:UntagResource"
          ]
          Resource = [
            "arn:aws:events:*:${data.aws_caller_identity.current.account_id}:rule/CloudScanner*",
            "arn:aws:events:*:${data.aws_caller_identity.current.account_id}:rule/upwind-cloud-scanner-ucsc-CloudScanner*"
          ]
          Condition = {
            StringEquals = {
              "aws:RequestTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid = "CloudScannerLambdaRulesModifyTags"
          # Permissions required to modify tags post creation
          Effect = "Allow"
          Action = [
            "events:TagResource",
            "events:UntagResource"
          ]
          Resource = [
            "arn:aws:events:*:${data.aws_caller_identity.current.account_id}:rule/CloudScanner*",
            "arn:aws:events:*:${data.aws_caller_identity.current.account_id}:rule/upwind-cloud-scanner-ucsc-CloudScanner*"
          ]
          Condition = {
            StringEquals = {
              "aws:ResourceTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid = "AccessUpwindS3ServerlessBucket",
          # This policy goes hand in hand with the policy above and helps limits the source for the Lambdas to the
          # Upwind publishing bucket.
          Effect = "Allow",
          Action = [
            "s3:GetObject"
          ],
          Resource = [
            "arn:aws:s3:::upwind-serverless-functions-*/integrations/cloudscanner/*"
          ],
          Condition = {
            StringEquals = {
              "aws:ResourceAccount" : "693339160499"
            }
          }
        },
        {
          Sid = "AccessCloudWatchEvents"
          # Permissions to manage CloudWatch Events.
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
          Resource = "*"
        },
        {
          Sid = "AccessIAMInstanceProfile"
          # The following IAM permissions are required to allow management of an IAM Instance Profile, which will be created when installing the CloudScanner
          # CloudFormation stack. The Instance Profile is used to grant (or pass) the CloudScanner Admin role through to the VMs running in the AutoScaling Group,
          # allowing them to function using that role. Unfortunately the conditions which can be applied to these actions are limited, see :-
          # https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsidentityandaccessmanagementiam.html#awsidentityandaccessmanagementiam-instance-profile
          # The actions defined here grant permissions to create the policy. The roles that can be attached to this policy are limited by using iam:PassRole action which
          # is limited to the CloudScanner Admin role. By default, it is only possible to attache a single role to an IAM Instance Policy, and when performing iam:PassRole
          # actions, the role being pass must match that defined in the Instance Policy.
          Effect = "Allow"
          Action = [
            "iam:AddRoleToInstanceProfile",
            "iam:CreateInstanceProfile",
            "iam:DeleteInstanceProfile",
            "iam:GetInstanceProfile",
            "iam:RemoveRoleFromInstanceProfile"
          ]
          Resource = [
            # An IAM Instance Policy will be created when provisioning the CloudScanner. It will be created in the orchestrator account similar to the following.
            "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:instance-profile/upwind-cs-pr-ucsc-*"
          ]
        },
        {
          Sid = "AccessIAMPassCloudscannerRole"
          # Permissions to pass the CloudScanner Admin role to the necessary resources and services
          # The Account Service role can be used to update the CloudScanner stack configuration. This includes applying configuration
          # changes to the ASG and launch templates. In order to do so, the role needs to pass the CloudScanner Admin role to the
          # necessary services.
          # This is effectively delegating permissions to the AWS services (Auto Scaling Group and EC2 services) to perform the
          # actions on the resources on our behalf
          # The role here must match the role configured in the instance policy associated with the ASG, otherwise it does not
          # appear to be assumed.
          Effect = "Allow"
          Action = [
            "iam:PassRole"
          ]
          Resource = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${var.cloudscanner_admin_role_name}"
          Condition = {
            StringEquals = {
              "iam:PassedToService" = [
                "ec2.amazonaws.com",
                "lambda.amazonaws.com"
              ]
            }
          }
        },
        {
          Sid = "AutoscalingServiceLinkedRoleCreatePolicy"
          # Permission to allow the creation of the AWSServiceRoleForAutoScaling role which
          # AWS may need to create automatically when creating the fist ASG if the role does not
          # already exist.
          Effect = "Allow"
          Action = [
            "iam:CreateServiceLinkedRole"
          ]
          Resource = [
            "arn:aws:iam::*:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling*"
          ]
          Condition = {
            StringLike = {
              "iam:AWSServiceName" = "autoscaling.amazonaws.com"
            }
          }
        },
        {
          Sid = "AutoscalingServiceLinkedRoleUsagePolicy"
          # Permission to allow the AWSServiceRoleForAutoScaling role to be attached as required.
          Effect = "Allow"
          Action = [
            "iam:AttachRolePolicy",
            "iam:PutRolePolicy"
          ]
          Resource = "arn:aws:iam::*:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling*"
        }
      ]
    }
  )

  tags = merge(
    var.custom_tags,
    {
      "upwind:aws:Component"      = "Onboarding",
      "upwind:aws:ReleaseVersion" = local.upwind_version
  })
}

resource "aws_iam_role_policy_attachment" "attach_cloudscanner_access_policy" {
  count = var.apply_for_orchestrator_account && var.upwind_cloudscanner_management_enabled ? 1 : 0

  role       = aws_iam_role.account_service_role.name
  policy_arn = one(aws_iam_policy.account_service_cloudscanner_access_policy[*].arn)
}
