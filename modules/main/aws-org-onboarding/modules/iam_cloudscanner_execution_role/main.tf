data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "cloudscanner_execution_role" {
  name        = var.cloudscanner_execution_role_name
  description = "Grants Upwind Security the necessary permissions to execute cloud scanning operations."
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Principal = {
            AWS = "arn:${data.aws_partition.current.partition}:iam::${var.orchestrator_account_id}:root"
          }
          Action = "sts:AssumeRole"
          Condition = {
            ArnLike = {
              "aws:PrincipalArn" = "arn:${data.aws_partition.current.partition}:iam::${var.orchestrator_account_id}:role/${var.cloudscanner_admin_role_name}"
            }
          }
        }
      ]
    }
  )

  tags = merge(
    var.custom_tags,
    {
      "upwind:aws:Component"          = "Onboarding",
      "upwind:aws:OnboardingType"     = "Org",
      "upwind:aws:ReleaseVersion"     = local.upwind_version,
      "upwind:aws:DSPMEnabled"        = var.upwind_feature_dspm_enabled
      "upwind:aws:DSPMEnabledAccount" = local.dspm_enabled,
    },
  )

}

resource "aws_iam_role_policy" "cloudscanner_execution_role_cloudscanner_access_policy" {
  name = "CloudScannerAccessPolicy"
  role = aws_iam_role.cloudscanner_execution_role.name

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Sid = "PermitEBSEncryptFromAnyCMK"
          # Permissions required to permit AWS EBS to encrypt from a customer provided CMK
          Effect = "Allow"
          Action = [
            "kms:ReEncryptFrom"
          ]
          Resource = "*"
          Condition = {
            # Allow the EC2 instance for any region - rather than the region the roles are created in.
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
          Sid = "PermitEBSToEncyptWithUpwindCMK"
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
          Sid    = "QueryEC2ResourcesVMScanning"
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
          # Tagged snapshot request. The request must include the UpwindComponent tag
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
              "aws:ResourceTag/UpwindComponent" = "CloudScanner"
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
          Sid = "ModifyTaggedSnapshotsAttribute"
          # Used to permit sharing of tagged snapshots
          Effect = "Allow"
          Action = [
            "ec2:ModifySnapshotAttribute"
          ]
          Resource = "arn:${data.aws_partition.current.partition}:ec2:*::snapshot/*"
          Condition = {
            StringEquals = {
              "aws:ResourceTag/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Sid = "EnsureSnapshotTaggingOnCreate"
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
                "CopySnapshot"
              ]
            }
          }
        },
        {
          Sid = "PermitSnapshotTaggingOnExistingTaggedResource"
          # Permission to allow tagging only if snapshot is already tagged (CloudScanner tagged)
          Effect = "Allow"
          Action = [
            "ec2:CreateTags"
          ]
          Resource = "arn:${data.aws_partition.current.partition}:ec2:*::snapshot/*"
          Condition = {
            StringEquals = {
              "aws:Resource/UpwindComponent" = "CloudScanner"
            }
          }
        },
        {
          Effect = "Allow"
          Action = [
            "ecr:GetAuthorizationToken",
            "ecr:ListImages",
            "ecr:DescribeRepositories",
            "ecr:BatchGetImage",
            "ecr:GetDownloadUrlForLayer"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "lambda:GetFunction"
          ]
          Resource = "*"
        },
        {
          Sid    = "DeleteOnlyTaggedSnapshots"
          Effect = "Allow"
          Action = [
            "ec2:DeleteSnapshot"
          ]
          Resource = "arn:${data.aws_partition.current.partition}:ec2:*::snapshot/*"
          Condition = {
            StringEquals = {
              "ec2:ResourceTag/UpwindComponent" = "CloudScanner"
            }
          }
        }
      ]
    }
  )
}

resource "aws_iam_role_policy" "cloudscanner_execution_role_cloudscanner_dspm_policy" {
  name = "CloudScannerDSPMPolicy"
  role = aws_iam_role.cloudscanner_execution_role.name

  count = local.dspm_enabled ? 1 : 0

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Sid = "PermitDSPMS3BucketAccess"
          # Permissions to allow the CloudScanner worker to access all S3 buckets within the account.
          Effect = "Allow"
          Action = [
            "s3:ListBucket",
            "s3:ListAllMyBuckets",
            "s3:GetObject"
          ]
          Resource = "*"
          Condition = {
            # Limit access to S3 buckets in the same account
            StringEquals = {
              "aws:ResourceAccount" = local.aws_account_id
            }
          }
        },
        {
          Sid = "PermitDSPMMetricAccess"
          # Grant permissions to allow the CloudScanner worker to retrieve metrics - eg to determine bucket sizes.
          Effect = "Allow"
          Action = [
            "cloudwatch:GetMetricStatistics"
          ]
          Resource = "*"
        }
      ]
    }
  )
}
