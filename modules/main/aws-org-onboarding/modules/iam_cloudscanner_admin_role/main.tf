data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}


resource "aws_iam_role" "cloudscanner_administration_role" {
  name        = var.cloudscanner_admin_role_name
  description = ""
  assume_role_policy = jsonencode(
    {
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
    }
  )

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

resource "aws_iam_role_policy" "cloudscanner_administration_role_cloudscanneroperational_access_policy" {
  name = "CloudScannerOperationalAccessPolicy"
  role = aws_iam_role.cloudscanner_administration_role.name

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          # Grant permissions to only create logs with the following paths
          Resource = [
            "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/system-logs/upwind-cs-ucsc-*"
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "lambda:GetFunction"
          ]
          Resource = "*"
        },
        {
          Sid = "EC2AndECRReadOnlyAccess"
          # Permissions to retrieve meta data associated with scannable EC2 ane ECR resources"
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
        {
          Sid = "EC2CreateSnapshotsFromVolumes"
          # Permission to create Tagged Snapshots from EBS Volumes. The internal implementation first requires an untagged request against the volume
          # followed by a tagged request against snapshots - hence this is implemented using 2 statements.
          Effect = "Allow"
          Action = [
            "ec2:CreateSnapshot",
            "ec2:CreateSnapshots"
          ]
          Resource = [
            "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:volume/*",
            "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*]"
          ]
        },
        {
          Sid = "EC2CreateSnapshotsFromVolumesSnapshotTagging"
          # Tagged snapshot request
          Effect = "Allow"
          Action = [
            "ec2:CreateSnapshot",
            "ec2:CreateSnapshots"
          ]
          Resource = "arn:${data.aws_partition.current.partition}:ec2:*::snapshot/*"
          Condition = {
            StringEquals = {
              "aws:RequestTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid = "EC2CopyTaggedSnapshotsExistingSnapshot"
          # Permission to copy a snapshot - a snapshot created previously by the CloudScanner
          # This verifies that the original snapshot was tagged and that the request is applying the same tag
          # However this requires 2 permission sets as the CopySnapshot is a 2 step process. The first step relates to the existing snapshot
          # which must be tagged, while the second ensures that the new snapshot is being created with the same tag.
          Effect = "Allow"
          Action = [
            "ec2:CopySnapshot"
          ]
          Resource = "arn:${data.aws_partition.current.partition}:ec2:*::snapshot/*"
          Condition = {
            StringEquals = {
              "ec2:ResourceTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid = "EC2CopyTaggedSnapshotToNewSnapshot"
          # Ensure the tag is being applied when creating the new snapshot
          Effect = "Allow"
          Action = [
            "ec2:CopySnapshot"
          ]
          Resource = "arn:${data.aws_partition.current.partition}:ec2:*::snapshot/*"
          Condition = {
            StringEquals = {
              "aws:RequestTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid = "EC2CCreateVolumeFromTaggedSnapshot"
          # Permission to create a volume from a tagged snapshot created previously by the CloudScanner (tagged)
          # Ideally this would verifies that the original snapshot was tagged, however this is not possible as tags are not shared between accounts (cross account scans).
          # Instead we will ensure that the new volume is tagged.
          # However this requires 2 permission sets as the CreateVolume is a 2 step process against 2 different resources. The first step relates to the existing snapshot,
          # while the second ensures that the new volume is being created with the CloudScanner tag.
          Effect = "Allow"
          Action = [
            "ec2:CreateVolume"
          ]
          Resource = "arn:${data.aws_partition.current.partition}:ec2:*::snapshot/*"
        },
        {
          Sid = "EC2EnsureTagIsAppliedToNewVolume"
          # Ensure the tag is being applied when creating the new Volume
          Effect = "Allow"
          Action = [
            "ec2:CreateVolume"
          ]
          Resource = "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:volume/*"
          Condition = {
            StringEquals = {
              "aws:RequestTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid = "EnsureSnapshotAndVolumeTaggingOnCreate"
          # Permission to ensure tag is provided when creating Snapshots and volumes
          Effect = "Allow"
          Action = [
            "ec2:CreateTags"
          ]
          Resource = "arn:${data.aws_partition.current.partition}:ec2:*::snapshot/*"
          Condition = {
            StringEquals = {
              "aws:RequestTag/UpwindComponent" = "CloudScanner",
              "ec2:CreateAction" = [
                "CreateSnapshot",
                "CreateSnapshots",
                "CopySnapshots",
                "CreateVolume"
              ]
            }
          }
        },
        {
          Sid = "PermitTaggingOnExistingTaggedResource"
          # Permission to allow tagging only if snapshot/volume is already tagged (CloudScanner tagged), and CloudScanner tag is not being modified
          Effect = "Allow"
          Action = [
            "ec2:CreateTags"
          ]
          Resource = [
            "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:snapshot/*",
            "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:volume/*"
          ]
          Condition = {
            StringEquals = {
              "aws:RequestTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid = "AttachDetachCloudScannerVolumes"
          # Permission to create Tagged Snapshots from EBS Volumes. The internal implementation first requires an untagged request against the volume
          # followed by a tagged request against snapshots - hence this is implemented using 2 statements.
          Effect = "Allow"
          Action = [
            "ec2:AttachVolume",
            "ec2:DetachVolume",
            "ec2:ModifyInstanceAttribute"
          ]
          Resource = "*"
          Condition = {
            StringEquals = {
              "ec2:ResourceTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid    = "DeleteScanningResources"
          Effect = "Allow"
          Action = [
            "ec2:DeleteSnapshot",
            "ec2:DeleteVolume"
          ]
          Resource = [
            "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:snapshot/*",
            "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:volume/*"
          ]

          Condition = {
            StringEquals = {
              "ec2:ResourceTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid    = "EBSDirectPermissions"
          Effect = "Allow"
          Action = [
            "ebs:ListSnapshotBlocks",
            "ebs:GetSnapshotBlock"
          ]
          Resource = "arn:aws:ec2:*:*:snapshot/*"
          Condition = {
            StringEquals = {
              "ec2:ResourceTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid    = "AccessUpwindSecrets"
          Effect = "Allow"
          Action = [
            "secretsmanager:ListSecrets",
            "secretsmanager:GetSecretValue"
          ]
          Resource = "*"
          Condition = {
            # We're using ARN like condition here as the ARN as the last 6 characters are auto generated and may change if the key is
            # modified or re-created. Granting permissions in this way at least allows us scope to handle that if it becomes a problem.
            ArnLike = {
              "secretsmanager:SecretId" = local.cloudscanner_secret_arnlike
            }
          }
        },
        {
          Effect = "Allow"
          Action = [
            "autoscaling:SetInstanceProtection"
          ]
          Resource = "*"
          Condition = {
            StringEquals = {
              "autoscaling:ResourceTag/Name" = "upwind-cs-asg-*"
            }
          }
        },
        {
          # Permission which allows the CloudScanner tagged Instance Template or Autoscaling group to be used or modified
          Effect = "Allow"
          Action = [
            "autoscaling:*",
            "ec2:*"
          ]
          Resource = [
            "arn:${data.aws_partition.current.partition}:autoscaling:*:${data.aws_caller_identity.current.account_id}:autoScalingGroup*:autoScalingGroupName/*",
            "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:launch-template/*"
          ],
          Condition = {
            StringEquals = {
              "autoscaling:ResourceTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          # Permission to allow lambda images to be fetched from S3 - only for CloudScanner resources
          Effect = "Allow"
          Action = [
            "s3:GetObject"
          ]
          Resource = [
            # S3 objects are limited to buckets and cannot include accounts ids.
            "arn:aws:s3:::upwind-serverless-functions-*/integrations/cloudscanner/*"
          ],
          Condition = {
            # Restricting S3 Access to the Upwind publishing account
            StringEquals = {
              "aws:ResourceAccount" : "693339160499"
            }
          }
        },
        {
          Effect = "Allow"
          Action = [
            "sts:AssumeRole"
          ]
          Resource = "arn:${data.aws_partition.current.partition}:iam::*:role/${var.cloudscanner_execution_role_name}"
        }
      ]
    }
  )
}

resource "aws_iam_role_policy" "cloudscanner_administration_role_cloudscannerscaler_access_policy" {
  name = "CloudScannerScalerAccessPolicy"
  role = aws_iam_role.cloudscanner_administration_role.name

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          # Grant permissions to only create logs with the following paths
          Resource = "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/upwind-cs-lambda-ucsc-*"
        },
        {
          # Restrict access to only the CloudScanner Secrets created within the Admin account
          Effect = "Allow"
          Action = [
            "secretsmanager:ListSecrets",
            "secretsmanager:GetSecretValue"
          ]
          Resource = "*"
          Condition = {
            # We're using ARN like condition here as the ARN as the last 6 characters are auto generated and may change if the key is
            # modified or re-created. Granting permissions in this way at least allows us scope to handle that if it becomes a problem.
            ArnLike = {
              "secretsmanager:SecretId" = local.cloudscanner_secret_arnlike
            }
          }
        },
        {
          # Permissions to pass the CloudScanner Admin role to the necessary resources and services
          # Need to grant permission for the Scaling Lambda to pass the necessary permissions to the ASG when applying changes.
          # This is effectively delegating permissions to the AWS services (Auto Scaling Group and EC2 services) to perform the
          # actions on the resources on our behalf
          # The role here must match the role configured in the instance policy associated with the ASG, otherwise it does not
          # appear to be assumed.
          Effect = "Allow"
          Action = [
            "iam:GetRole",
            "iam:PassRole"
          ]
          Resource = "arn:${data.aws_partition.current.partition}:iam::*:role/${var.cloudscanner_admin_role_name}"
          Condition = {
            StringEquals = {
              "iam:PassedToService" = [
                "ec2.amazonaws.com",
                "autoscaling.amazonaws.com"
              ]
            }
          }
        },
        {
          # Permission to allow autoscaling actions to be perform on the CloudScanner tagged scaling groups.
          Effect = "Allow"
          Action = [
            "autoscaling:*",
          ]
          Resource = [
            "arn:${data.aws_partition.current.partition}:autoscaling:*:${data.aws_caller_identity.current.account_id}:autoScalingGroup*:autoScalingGroupName/*"
          ],
          Condition = {
            StringEquals = {
              "autoscaling:ResourceTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          # Permissions which will allow the CloudScanner Lambda apply changes to the CloudScanner ASG launch templates
          Action = [
            "ec2:CreateLaunchTemplateVersion",
            "ec2:ModifyLaunchTemplate",
            "ec2:DeleteLaunchTemplateVersions",
            "ec2:RunInstances"
          ],
          Effect = "Allow",
          Resource = [
            "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:launch-template/*"
          ],
          Condition = {
            StringEquals : {
              "aws:ResourceTag/UpwindComponent" : "CloudScanner"
            }
          }
        },
        {
          Effect = "Allow"
          Action = [
            "autoscaling:Describe*",
            "ec2:Describe*",
          ]
          Resource = "*"
        },
        {
          # The following permissions are granted to allow the Lambda to alter the running state of the Auto scaling group.
          # When doing so it performs a DryRun of an instances to ensure the changes to the ASG and template are valid.
          Effect = "Allow",
          Action = "ec2:RunInstances",
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
          ],
          Condition = {
            ArnLike : {
              "ec2:LaunchTemplate" : "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:launch-template/*"
            }
          }
        },
        {
          Effect = "Allow"
          Action = [
            "sts:AssumeRole"
          ]
          Resource = [
            "arn:${data.aws_partition.current.partition}:iam::*:role/${var.cloudscanner_execution_role_name}"
          ]
        },

      ]
    }
  )
}

resource "aws_iam_role_policy" "cloudscanner_administration_role_cloudscannersnapshotter_access_policy" {
  name = "CloudScannerSnapshotterAccessPolicy"
  role = aws_iam_role.cloudscanner_administration_role.name

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Sid = "PermitEBSDecryptFromAnyCMK"
          # Permissions required to permit AWS EBS to decrypt/re-encrypt resources encrypted with a customer provided CMK          
          Effect = "Allow"
          Action = [
            "kms:ReEncrypt*",
            "kms:Decrypt"
          ]
          Resource = "*"
          Condition = {
            StringLike = {
              "kms:ViaService" = "ec2.*.amazonaws.com"
            }
          }
        },
        {
          Sid = "PermitEBSToGrantForAnyCMK"
          # Permissions require to permit only AWS EBS, or any AWS service, to create grants to use a customer CMK          
          Effect = "Allow"
          Action = [
            "kms:CreateGrant"
          ]
          Resource = "*"
          Condition = {
            Bool = {
              "kms:GrantIsForAWSResource" = "true"
            }
          }
        },
        {
          Sid = "PermitEBSToEncryptWithUpwindCMK"
          # Permit re-encryption using CloudScanner CMK in central account          
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
            StringEquals = {
              "aws:ResourceTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Effect = "Allow"
          Action = [
            "ec2:DescribeInstances",
            "ec2:DescribeVolumes",
            "ec2:DescribeRegions",
            "ec2:DescribeSnapshots",
            "ec2:DescribeSnapshotAttribute",
            "ec2:DescribeFleetInstances",
            "autoscaling:DescribeAutoScalingGroups"
          ]
          Resource = "*"
        },
        {
          # Restrict access to only the CloudScanner Secrets created within the Admin account
          Effect = "Allow"
          Action = [
            "secretsmanager:ListSecrets",
            "secretsmanager:GetSecretValue"
          ]
          Resource = "*"
          Condition = {
            # We're using ARN like condition here as the ARN as the last 6 characters are auto generated and may change if the key is
            # modified or re-created. Granting permissions in this way at least allows us scope to handle that if it becomes a problem.
            ArnLike = {
              "secretsmanager:SecretId" = local.cloudscanner_secret_arnlike
            }
          }
        },
        {
          Effect = "Allow"
          Action = [
            "ec2:DeleteSnapshot"
          ]
          Resource = "*"
          Condition = {
            StringEquals = {
              "ec2:ResourceTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          # Grant permissions to only create logs with the following paths
          Resource = [
            "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/upwind-cs-lambda-ucsc-*"
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "sts:AssumeRole"
          ]
          Resource = [
            "arn:${data.aws_partition.current.partition}:iam::*:role/${var.cloudscanner_execution_role_name}"
          ]
        }
      ]
    }
  )
}

resource "aws_iam_role_policy" "cloudscanner_administration_role_cloudscannerupdater_access_policy" {
  name = "CloudScannerUpdaterAccessPolicy"
  role = aws_iam_role.cloudscanner_administration_role.name

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          # Grant permissions to only create logs with the following paths
          Resource = [
            "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/upwind-cs-lambda-ucsc-*"
          ]
        },
        {
          # This policy is used to perform code updates on the Upwind named lambda functions, and also permits version management of those functions.
          # Unfortunately the full names of the Lambdas are unknown when creating the roles.
          Effect = "Allow"
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
            "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:upwind-cs-lambda-ucsc-*",
            "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:upwind-cs-ss-lambda-ucsc-*",
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject"
          ]
          Resource = [
            # S3 objects are limited to buckets and cannot include accounts ids.
            "arn:aws:s3:::upwind-serverless-functions-*/integrations/cloudscanner/*"
          ],
          Condition = {
            # Restricting S3 Access to the Upwind publishing account
            StringEquals = {
              "aws:ResourceAccount" : "693339160499"
            }
          }
        }
      ]
    }
  )
}
