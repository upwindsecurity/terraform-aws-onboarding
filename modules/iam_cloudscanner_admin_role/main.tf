data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


resource "aws_iam_role" "cloudscanner_administration_role" {
  name = var.cloudscanner_admin_role_name
  path = (var.iam_role_path != "/") ? var.iam_role_path : null
  # Optionally constrain the role with a caller-supplied permissions boundary (null when none was provided).
  permissions_boundary = local.permissions_boundary_arn
  description          = ""
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "ec2.amazonaws.com",
            "lambda.amazonaws.com"
          ]
        }
        Action = "sts:AssumeRole"
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

resource "aws_iam_role_policy_attachment" "cloudscanner_administration_role_awsssm_policy_attachment" {
  role       = aws_iam_role.cloudscanner_administration_role.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedEC2InstanceDefaultPolicy"
}

# VPC networking permissions (elastic network interfaces) for the in-VPC DSPM RDS scanning lambda, which runs as
# this role; only with DSPM RDS.
resource "aws_iam_role_policy" "cloudscanner_administration_role_dspm_rds_executor_vpc_eni_policy" {
  count = var.dspm_rds_enabled ? 1 : 0

  name = "DspmRdsExecutorVpcEniPolicy"
  role = aws_iam_role.cloudscanner_administration_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # DescribeNetworkInterfaces takes no resource-level scoping. CreateNetworkInterface is evaluated
      # against the new ENI plus the subnet and security group it lands in, so it stays on "*" as well.
      {
        Sid    = "DspmRdsExecutorVpcEniCreateDescribe"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces"
        ]
        Resource = "*"
      },
      # Lambda deletes the executor's Hyperplane ENIs with this role on teardown / VPC-config change, so
      # the permission must stay, but it only ever targets ENIs in this account. Lambda does not tag
      # these ENIs and the scanner VPC is created after this stack, so tag/VPC conditions are not
      # usable here; the account-scoped ARN is the guardrail. Region stays * because the scanner stack
      # may be deployed in any region of the account.
      {
        Sid    = "DspmRdsExecutorVpcEniManage"
        Effect = "Allow"
        Action = [
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudscanner_administration_role_cloudscanneroperational_access_policy" {
  name = "CloudScannerOperationalAccessPolicy"
  role = aws_iam_role.cloudscanner_administration_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudScannerLogging"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          # Grant permissions to only create logs with the following paths
          "arn:${data.aws_partition.current.partition}:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/system-logs/upwind-cs-ucsc-*"
        ]
      },
      {
        Sid      = "GetLambdaFunctionForScanning"
        Effect   = "Allow"
        Action   = ["lambda:GetFunction"]
        Resource = "*"
      },
      # Permissions to retrieve meta data associated with scannable EC2 ane ECR resources
      {
        Sid    = "EC2AndECRReadOnlyAccess"
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "ecr:GetAuthorizationToken",
          "ecr:ListImages",
          "ecr:DescribeRepositories",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = "*"
      },
      # Permission to create Tagged Snapshots from EBS Volumes. The internal implementation first requires an untagged request against the volume
      # followed by a tagged request against snapshots - hence this is implemented using 2 statements.
      {
        Sid    = "EC2CreateSnapshotsFromVolumes"
        Effect = "Allow"
        Action = [
          "ec2:CreateSnapshot",
          "ec2:CreateSnapshots"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:volume/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*"
        ]
      },
      # Tagged snapshot request
      {
        Sid    = "EC2CreateSnapshotsFromVolumesSnapshotTagging"
        Effect = "Allow"
        Action = [
          "ec2:CreateSnapshot",
          "ec2:CreateSnapshots"
        ]
        Resource = ["arn:${data.aws_partition.current.partition}:ec2:*::snapshot/*"]
        Condition = {
          StringEquals = { "aws:RequestTag/UpwindComponent" = "CloudScanner" }
        }
      },
      # Permission to copy a snapshot - a snapshot created previously by the CloudScanner
      # This verifies that the original snapshot was tagged and that the request is applying the same tag
      # However this requires 2 permission sets as the CopySnapshot is a 2 step process. The first step relates to the existing snapshot
      # which must be tagged, while the second ensures that the new snapshot is being created with the same tag.
      {
        Sid      = "EC2CopyTaggedSnapshotsExistingSnapshot"
        Effect   = "Allow"
        Action   = ["ec2:CopySnapshot"]
        Resource = ["arn:${data.aws_partition.current.partition}:ec2:*::snapshot/*"]
        Condition = {
          StringEquals = { "aws:ResourceTag/UpwindComponent" = "CloudScanner" }
        }
      },
      # Ensure the tag is being applied when creating the new snapshot
      {
        Sid      = "EC2CopyTaggedSnapshotToNewSnapshot"
        Effect   = "Allow"
        Action   = ["ec2:CopySnapshot"]
        Resource = ["arn:${data.aws_partition.current.partition}:ec2:*::snapshot/*"]
        Condition = {
          StringEquals = { "aws:RequestTag/UpwindComponent" = "CloudScanner" }
        }
      },
      # Permission to create a snapshot - a snapshot created previously by the CloudScanner (tagged)
      # Ideally this would verifies that the original snapshot was tagged, however this is not possible as tags are not shared between accounts (cross account scans).
      # Instead we will ensure that the new volume is tagged.
      # However this requires 2 permission sets as the CreateVolume is a 2 step process against 2 different resources. The first step relates to the existing snapshot,
      # while the second ensures that the new volume is being created with the CloudScanner tag.
      {
        Sid      = "EC2CCreateVolumeFromTaggedSnapshot"
        Effect   = "Allow"
        Action   = ["ec2:CreateVolume"]
        Resource = ["arn:${data.aws_partition.current.partition}:ec2:*::snapshot/*"]
      },
      # Ensure the tag is being applied when creating the new Volume
      {
        Sid      = "EC2EnsureTagIsAppliedToNewVolume"
        Effect   = "Allow"
        Action   = ["ec2:CreateVolume"]
        Resource = ["arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:volume/*"]
        Condition = {
          StringEquals = { "aws:RequestTag/UpwindComponent" = "CloudScanner" }
        }
      },
      # Permission to allow tagging only when creating the snapshots
      {
        Sid    = "PermitSnapshotTaggingOnCreate"
        Effect = "Allow"
        Action = ["ec2:CreateTags"]
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:*::snapshot/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:volume/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*"
        ]
        Condition = {
          StringEquals = {
            "aws:RequestTag/UpwindComponent" = "CloudScanner"
            "ec2:CreateAction" = [
              "CreateSnapshot",
              "CreateSnapshots",
              "CopySnapshot",
              "CreateVolume"
            ]
          }
        }
      },
      # Permission to allow tagging only if snapshot/volume is already tagged (CloudScanner tagged), and CloudScanner tag is not being modified
      {
        Sid    = "PermitTaggingOnExistingTaggedResource"
        Effect = "Allow"
        Action = ["ec2:CreateTags"]
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:*::snapshot/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:volume/*"
        ]
        Condition = {
          StringEquals = {
            "aws:ResourceTag/UpwindComponent" = "CloudScanner"
            "aws:RequestTag/UpwindComponent"  = "CloudScanner"
          }
        }
      },
      {
        Sid    = "AttachDetachCloudScannerVolumes"
        Effect = "Allow"
        Action = [
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:ModifyInstanceAttribute"
        ]
        Resource = "*"
        Condition = {
          StringEquals = { "ec2:ResourceTag/UpwindComponent" = "CloudScanner" }
        }
      },
      {
        Sid    = "DeleteScanningResources"
        Effect = "Allow"
        Action = [
          "ec2:DeleteSnapshot",
          "ec2:DeleteVolume"
        ]
        Resource = "*"
        Condition = {
          StringEquals = { "ec2:ResourceTag/UpwindComponent" = "CloudScanner" }
        }
      },
      {
        Sid    = "EBSDirectPermissions"
        Effect = "Allow"
        Action = [
          "ebs:ListSnapshotBlocks",
          "ebs:GetSnapshotBlock"
        ]
        Resource = ["arn:${data.aws_partition.current.partition}:ec2:*:*:snapshot/*"]
        Condition = {
          StringEquals = { "aws:ResourceTag/UpwindComponent" = "CloudScanner" }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["autoscaling:SetInstanceProtection"]
        Resource = "*"
        Condition = {
          StringLike = { "autoscaling:ResourceTag/Name" = "upwind-cs-asg-*" }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudscanner_administration_role_cloudscannersecrets_access_policy" {
  name = "CloudScannerSecretsAccessPolicy"
  role = aws_iam_role.cloudscanner_administration_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AccessUpwindSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:ListSecrets",
          "secretsmanager:GetSecretValue"
        ]
        Resource = "*"
        Condition = {
          # An ARN-like condition, as the secret is either the one provided (its full ARN) or the one created by the
          # onboarding (its ARN without the random suffix, which can change when the secret is updated).
          ArnLike = { "secretsmanager:SecretId" = var.create_cloudscanner_secret ? "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:${var.credentials_secret_name_prefix}/cloudscanner-credentials-${var.role_name_suffix}*" : var.cloudscanner_secret_arn }
        }
      },
      # Harness Artifact Registry credentials live in a customer-created secret; the tag is
      # the customer's grant and kill switch, so no list permission and no name coupling.
      {
        Sid    = "ReadTaggedArtifactRegistrySecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
        Condition = {
          StringEquals = { "aws:ResourceTag/upwind-artifact-registry" = "true" }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudscanner_administration_role_cloudscannerscaler_access_policy" {
  name = "CloudScannerScalerAccessPolicy"
  role = aws_iam_role.cloudscanner_administration_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          # Grant permissions to only create logs with the following paths
          "arn:${data.aws_partition.current.partition}:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/upwind-cs-lambda-ucsc-*"
        ]
      },
      # Permissions to pass the CloudScanner Admin role to the necessary resources and services
      # Need to grant permission for the Scaling Lambda to pass the necessary permissions to the ASG when applying changes.
      # This is effectively delegating permissions to the AWS services (Auto Scaling Group and EC2 services) to perform the
      # actions on the resources on our behalf
      # The role here must match the role configured in the instance policy associated with the ASG, otherwise it does not
      # appear to be assumed.
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:PassRole"
        ]
        Resource = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role${var.iam_role_path}${var.cloudscanner_admin_role_name}"]
        Condition = {
          StringEquals = {
            "iam:PassedToService" = [
              "ec2.amazonaws.com",
              "autoscaling.amazonaws.com"
            ]
          }
        }
      },
      # Permission to allow autoscaling actions to be perform on the CloudScanner tagged scaling groups.
      {
        Sid    = "AllowAutoscalingActionsOnCloudScannerTaggedASGs"
        Effect = "Allow"
        Action = [
          "autoscaling:CancelInstanceRefresh",
          "autoscaling:DescribeAccountLimits",
          "autoscaling:DetachInstances",
          "autoscaling:LaunchInstances",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:SetInstanceProtection",
          "autoscaling:StartInstanceRefresh",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Resource = ["arn:${data.aws_partition.current.partition}:autoscaling:*:${data.aws_caller_identity.current.account_id}:autoScalingGroup*:autoScalingGroupName/*"]
        Condition = {
          StringEquals = { "autoscaling:ResourceTag/UpwindComponent" = "CloudScanner" }
        }
      },
      # Permissions which will allow the CloudScanner Lambda apply changes to the CloudScanner ASG launch templates
      {
        Sid    = "AllowEC2ActionsOnCloudScannerTaggedLaunchTemplates"
        Effect = "Allow"
        Action = [
          "ec2:CreateLaunchTemplateVersion",
          "ec2:ModifyLaunchTemplate",
          "ec2:DeleteLaunchTemplateVersions",
          "ec2:RunInstances"
        ]
        Resource = ["arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:launch-template/*"]
        Condition = {
          StringEquals = { "aws:ResourceTag/UpwindComponent" = "CloudScanner" }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:Describe*",
          "ec2:Describe*"
        ]
        Resource = "*"
      },
      # The following permissions are granted to allow the Lambda to alter the running state of the Auto scaling group.
      # When doing so Auto Scaling performs a RunInstances DryRun as the Lambda to ensure the changes to the ASG and
      # template are valid. RunInstances is authorised once per resource ARN, and the dry run carries no tags for the
      # instance, volume or network-interface it would create: neither aws:RequestTag nor aws:ResourceTag is present
      # in the request context for those resources (verified with CloudTrail on UP-8858), so a tag condition on them
      # always denies the dry run. The CloudScanner tag is enforced on the launch-template ARN instead
      # (AllowEC2ActionsOnCloudScannerTaggedLaunchTemplates): the launch template is one of the ARNs RunInstances is
      # authorised against, so an untagged template is denied regardless of this statement.
      {
        Sid    = "AllowDryRunInstancesOnLaunchResources"
        Effect = "Allow"
        Action = ["ec2:RunInstances"]
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:network-interface/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:volume/*"
        ]
        Condition = {
          ArnLike = { "ec2:LaunchTemplate" = "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:launch-template/*" }
        }
      },
      {
        Sid    = "AllowDryRunInstancesOnReferencedResources"
        Effect = "Allow"
        Action = ["ec2:RunInstances"]
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:security-group/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:*:subnet/*",
          "arn:${data.aws_partition.current.partition}:ec2:*::image/ami-*",
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:key-pair/*"
        ]
        Condition = {
          ArnLike = { "ec2:LaunchTemplate" = "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:launch-template/*" }
        }
      },
      # The statements AllowAutoscalingActionsOnCloudScannerTaggedASGs,  AllowRunInstancesWithCloudScannerTagOnlyforASGs and
      # AllowTaggingOnlyIfCloudScannerTagIsPresentAndOnlyforASGs combine together so that the Iam permissions allow the auto scaling group to be mutated securely.
      # * AllowTaggingOnlyIfCloudScannerTagIsPresentAndOnlyforASGs permits CloudScanner tagged ASGs to be updated.
      # * AllowRunInstancesWithCloudScannerTagOnlyforASGs allows runInstances to be invoked so long as the CloudScanner tag is present in the request,
      #   and the request is being made by the AWS autoscaling service.
      # * AllowTaggingOnlyIfCloudScannerTagIsPresentAndOnlyforASGs grants permissions to add tags to the necessary resources only if the CloudScanner tag is present
      #   in the request, and that the request is being made by the AWS autoscaling service. This is required as when the ASG performs a scale out, it needs to tag
      #   the new instances with the same tags as the ASG, including the CloudScanner tag, and without this permission, the tagging would fail, which in turn causes
      #   the runInstances call to fail as the tags are not applied.
      # Tags can only be added to the resources when creating new instances and creating new instances is only possible when the request is from the AWS autoscaling
      # service. It should only be possible to create new EC2 instances through the Autoscaling service
      {
        Sid    = "AllowRunInstancesWithCloudScannerTagOnlyforASGs"
        Effect = "Allow"
        Action = ["ec2:RunInstances"]
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:*:*:instance/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:*:volume/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:*:network-interface/*"
        ]
        Condition = {
          StringEquals = { "aws:RequestTag/UpwindComponent" = "CloudScanner" }
          "ForAnyValue:StringEquals" = {
            "aws:CalledVia" = ["autoscaling.amazonaws.com"]
          }
          Null = { "aws:RequestTag/aws:autoscaling:groupName" = false }
        }
      },
      {
        Sid    = "AllowTaggingOnlyIfCloudScannerTagIsPresentAndOnlyforASGs"
        Effect = "Allow"
        Action = ["ec2:CreateTags"]
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:*:*:instance/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:*:volume/*",
          "arn:${data.aws_partition.current.partition}:ec2:*:*:network-interface/*"
        ]
        Condition = {
          StringEquals = {
            "ec2:CreateAction"               = "RunInstances"
            "aws:RequestTag/UpwindComponent" = "CloudScanner"
          }
          "ForAnyValue:StringEquals" = {
            "aws:CalledVia" = ["autoscaling.amazonaws.com"]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudscanner_administration_role_cloudscannersnapshotter_access_policy" {
  name = "CloudScannerSnapshotterAccessPolicy"
  role = aws_iam_role.cloudscanner_administration_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Permissions required to permit AWS EBS to decrypt/re-encrypt resources encrypted with a customer provided CMK
      {
        Sid    = "PermitEBSDecryptFromAnyCMK"
        Effect = "Allow"
        Action = [
          "kms:ReEncrypt*",
          "kms:Decrypt"
        ]
        Resource = "*"
        Condition = {
          StringLike = { "kms:ViaService" = "ec2.*.${data.aws_partition.current.dns_suffix}" }
        }
      },
      # Permissions require to permit only AWS EBS, or any AWS service, to create grants to use a customer CMK
      {
        Sid      = "PermitEBSToGrantForAnyCMK"
        Effect   = "Allow"
        Action   = ["kms:CreateGrant"]
        Resource = "*"
        Condition = {
          Bool = { "kms:GrantIsForAWSResource" = "true" }
        }
      },
      # Permits the snapshotting lambda to perform pre-flight KMS availability checks prior
      # to snapshotting
      {
        Sid      = "PermitCloudscannerToCheckIfExistingKMSAvailableForScans"
        Effect   = "Allow"
        Action   = ["kms:DescribeKey"]
        Resource = "*"
      },
      # Permit re-encryption using CloudScanner CMK in central account
      {
        Sid    = "PermitEBSToEncryptWithUpwindCMK"
        Effect = "Allow"
        Action = [
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:CreateGrant",
          "kms:ReEncryptTo",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = { "aws:ResourceTag/UpwindComponent" = "CloudScanner" }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:DescribeRegions",
          "ec2:DescribeSnapshots",
          "ec2:DescribeSnapshotAttribute"
        ]
        Resource = "*"
      },
      # The secrets (CloudScannerSecretsAccessPolicy) and lambda log (Scaler policy) permissions are granted
      # once for the whole role, to keep its inline policies under the IAM size limit.
      {
        Effect   = "Allow"
        Action   = ["ec2:DeleteSnapshot"]
        Resource = "*"
        Condition = {
          StringEquals = { "ec2:ResourceTag/UpwindComponent" = "CloudScanner" }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudscanner_administration_role_cloudscannerupdater_access_policy" {
  name = "CloudScannerUpdaterAccessPolicy"
  role = aws_iam_role.cloudscanner_administration_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Effect = "Allow"
          # This policy is used to perform code updates on the Upwind named lambda functions, and also permits version management of those functions.
          # Unfortunately the full names of the Lambdas are unknown when creating the roles.
          Action = [
            "lambda:GetFunction",
            "lambda:UpdateFunctionCode",
            "lambda:DeleteFunction",
            "lambda:GetFunctionConfiguration",
            "lambda:GetFunctionUrlConfig",
            "lambda:GetFunctionCodeSigningConfig",
            "lambda:GetFunctionConcurrency",
            "lambda:GetFunctionEventInvokeConfig",
            "lambda:GetFunctionRecursionConfig",
            "lambda:GetPolicy",
            "lambda:ListAliases",
            "lambda:ListFunctionEventInvokeConfigs",
            "lambda:ListFunctionUrlConfigs",
            "lambda:ListProvisionedConcurrencyConfigs",
            "lambda:ListTags",
            "lambda:ListVersionsByFunction"
          ]
          Resource = [
            "arn:${data.aws_partition.current.partition}:lambda:*:${data.aws_caller_identity.current.account_id}:function:upwind-cs-lambda-ucsc-*",
            "arn:${data.aws_partition.current.partition}:lambda:*:${data.aws_caller_identity.current.account_id}:function:upwind-cs-ss-lambda-ucsc-*",
            "arn:${data.aws_partition.current.partition}:lambda:*:${data.aws_caller_identity.current.account_id}:function:upwind-cs-dspm-rds-executor-ucsc-*"
          ]
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
          }
        }
      ],
      # China only: anonymous S3 access is not available there, so workers read the install script and
      # binaries from the Upwind distribution buckets (owned by the Upwind publishing account) via signed
      # GetObject. The prod bucket names are the literal; the dev publish rewrites -prod- to -dev-.
      (data.aws_partition.current.partition == "aws-cn") ? [
        {
          Effect = "Allow"
          Sid    = "AccessUpwindS3ArtifactBuckets"
          Action = ["s3:GetObject"]
          Resource = [
            "arn:${data.aws_partition.current.partition}:s3:::upwind-get-prod-${data.aws_region.current.region}/*",
            "arn:${data.aws_partition.current.partition}:s3:::upwind-releases-prod-${data.aws_region.current.region}/*"
          ]
          Condition = {
            StringEquals = { "aws:ResourceAccount" = local.partition.publishing_account }
          }
        }
      ] : []
    )
  })
}

resource "aws_iam_role_policy" "cloudscanner_administration_role_assume_execution_role_policy" {
  name = "CloudScannerAssumeExecutionRolePolicy"
  role = aws_iam_role.cloudscanner_administration_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Grant permissions to assume the execution role for cross account scanning purposes. Also grant permissions to allow the session to be tagged with a "secret token"
      # to enhance security
      {
        Sid      = "CloudScannerAssumeExecutionRole"
        Effect   = "Allow"
        Action   = ["sts:AssumeRole"]
        Resource = ["arn:${data.aws_partition.current.partition}:iam::*:role${var.iam_role_path}${var.cloudscanner_execution_role_name}"]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "cloudscanner_administration_role_instance_profile" {
  name = var.cloudscanner_admin_role_profile_name
  path = (var.iam_role_path != "/") ? var.iam_role_path : null
  role = aws_iam_role.cloudscanner_administration_role.name
}
