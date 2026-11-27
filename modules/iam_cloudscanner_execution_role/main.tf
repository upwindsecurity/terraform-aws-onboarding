data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "cloudscanner_execution_role" {
  name = var.cloudscanner_execution_role_name
  path = (var.iam_role_path != "/") ? var.iam_role_path : null
  # Optionally constrain the role with a caller-supplied permissions boundary (null when none was provided).
  permissions_boundary = local.permissions_boundary_arn
  description          = "Grants Upwind Security the necessary permissions to execute cloud scanning operations."
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid       = "CloudScannerDefaultOrchestratorAccountExecutionAssumePolicy"
          Effect    = "Allow"
          Principal = { AWS = var.orchestrator_account_id }
          Action    = "sts:AssumeRole"
          Condition = var.is_saas_mode ? {
            ArnLike = {
              # In SaaS mode, trust the CloudScanner SaaS Customer Assume role in the orchestrator account (assumed by the Upwind SaaS).
              "aws:PrincipalArn" = "arn:${data.aws_partition.current.partition}:iam::${var.orchestrator_account_id}:role${var.iam_role_path}${var.cloudscanner_saas_customer_assume_role_name}"
            }
            } : {
            ArnLike = {
              # Otherwise (Outpost), trust the CloudScanner Administration role in the orchestrator account.
              "aws:PrincipalArn" = "arn:${data.aws_partition.current.partition}:iam::${var.orchestrator_account_id}:role${var.iam_role_path}${var.cloudscanner_admin_role_name}"
            }
          }
        }
      ],
      (join("", var.additional_orchestrator_account_ids) != "") ? [
        {
          Sid       = "CloudScannerAdditionalAccountsExecutionAssumePolicy"
          Effect    = "Allow"
          Principal = { AWS = var.additional_orchestrator_account_ids }
          Action    = "sts:AssumeRole"
          Condition = {
            ArnLike = { "aws:PrincipalArn" = "arn:${data.aws_partition.current.partition}:iam::*:role${var.iam_role_path}${var.cloudscanner_admin_role_name}" }
          }
        }
      ] : []
    )
  })

  tags = merge(
    var.custom_tags,
    {
      "upwind:aws:Component"      = "Onboarding"
      "upwind:aws:ReleaseVersion" = local.upwind_version
      # DSPMEnabled records what was asked for; DSPMEnabledAccount records what this account actually got,
      # from the condition that gates CloudScannerDSPMPolicy (the role's only s3:ListBucket/s3:GetObject grant).
      # CloudScanner reads DSPMEnabledAccount to avoid scheduling bucket scans into accounts that can't read them.
      "upwind:aws:DSPMEnabled"        = var.upwind_feature_dspm_enabled ? "Yes" : "No"
      "upwind:aws:DSPMEnabledAccount" = local.dspm_enabled ? "Yes" : "No"
    },
  )
}

resource "aws_iam_role_policy" "cloudscanner_execution_role_cloudscanner_access_policy" {
  name = "CloudScannerAccessPolicy"
  role = aws_iam_role.cloudscanner_execution_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Permissions required to permit AWS EBS to encrypt from a customer provided CMK
      {
        Sid      = "PermitEBSEncryptFromAnyCMK"
        Effect   = "Allow"
        Action   = ["kms:ReEncryptFrom"]
        Resource = "*"
        Condition = {
          # Allow the EC2 instance for any region - rather than the region the roles are created in.
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
          Bool = { "kms:GrantIsForAWSResource" = true }
        }
      },
      # Permission to broadly check KMS keys, so that CloudScanner can assess if we have access to them
      # when performing snapshots on encrypted targets
      {
        Sid      = "PermitCloudscannerToCheckIfExistingKMSAvailableForScans"
        Effect   = "Allow"
        Action   = ["kms:DescribeKey"]
        Resource = "*"
      },
      # Permit decryption /  re-encryption using CloudScanner CMK in central account - only on tagged resources
      {
        Sid    = "PermitEBSToEncryptWithUpwindCMK"
        Effect = "Allow"
        Action = [
          "kms:DescribeKey",
          "kms:Decrypt",
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
        Sid    = "QueryEC2ResourcesVMScanning"
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
      # Ensure the tag is being applied when creating the new snapshot
      {
        Sid      = "ModifyTaggedSnapshots"
        Effect   = "Allow"
        Action   = ["ec2:ModifySnapshotAttribute"]
        Resource = ["arn:${data.aws_partition.current.partition}:ec2:*::snapshot/*"]
        Condition = {
          StringEquals = merge(
            { "aws:ResourceTag/UpwindComponent" = "CloudScanner" },
            # Outpost: limit sharing to the orchestrator accounts. SaaS: unrestricted, as the snapshots are
            # shared with an account that is not an orchestrator account.
            var.is_saas_mode ? {} : {
              "ec2:Add/UserId" = [split(",", join(",", [
                var.orchestrator_account_id,
                join(",", var.additional_orchestrator_account_ids)
              ])), var.orchestrator_account_id][(join("", var.additional_orchestrator_account_ids) != "") ? 0 : 1]
            }
          )
        }
      },
      # Permission to allow tagging only when creating the snapshots
      {
        Sid      = "PermitSnapshotTaggingOnCreate"
        Effect   = "Allow"
        Action   = ["ec2:CreateTags"]
        Resource = ["arn:${data.aws_partition.current.partition}:ec2:*::snapshot/*"]
        Condition = {
          StringEquals = {
            "aws:RequestTag/UpwindComponent" = "CloudScanner"
            "ec2:CreateAction" = [
              "CreateSnapshot",
              "CreateSnapshots",
              "CopySnapshot"
            ]
          }
        }
      },
      # Permission to allow tagging only if snapshot is already tagged (CloudScanner tagged)
      {
        Sid      = "PermitSnapshotTaggingOnExistingTaggedResource"
        Effect   = "Allow"
        Action   = ["ec2:CreateTags"]
        Resource = ["arn:${data.aws_partition.current.partition}:ec2:*::snapshot/*"]
        Condition = {
          StringEquals = { "aws:ResourceTag/UpwindComponent" = "CloudScanner" }
        }
      },
      {
        Sid    = "QueryECRResources"
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
        Effect   = "Allow"
        Action   = ["lambda:GetFunction"]
        Resource = "*"
      },
      {
        Sid      = "DeleteSnapshot"
        Effect   = "Allow"
        Action   = ["ec2:DeleteSnapshot"]
        Resource = "arn:${data.aws_partition.current.partition}:ec2:*::snapshot/*"
        Condition = {
          StringEquals = { "ec2:ResourceTag/UpwindComponent" = "CloudScanner" }
        }
      },
      # EBS Direct Permissions (for marketplace AMIs)
      {
        Sid    = "QueryEBSDirect"
        Effect = "Allow"
        Action = [
          "ebs:ListSnapshotBlocks",
          "ebs:GetSnapshotBlock"
        ]
        Resource = ["arn:${data.aws_partition.current.partition}:ec2:*:*:snapshot/*"]
        Condition = {
          StringEquals = { "aws:ResourceTag/UpwindComponent" = "CloudScanner" }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudscanner_execution_role_cloudscanner_dspm_policy" {
  name = "CloudScannerDSPMPolicy"
  role = aws_iam_role.cloudscanner_execution_role.name

  count = local.dspm_enabled ? 1 : 0

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Permissions to allow the CloudScanner worker to access all S3 buckets within the account.
      {
        Sid    = "PermitDSPMS3BucketAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:ListAllMyBuckets",
          "s3:GetObject"
        ]
        Resource = "*"
        Condition = {
          StringEquals = { "aws:ResourceAccount" = data.aws_caller_identity.current.account_id }
        }
      },
      # Grant permissions to allow the CloudScanner worker to retrieve metrics - eg to determine bucket sizes.
      {
        Sid      = "PermitDSPMMetricAccess"
        Effect   = "Allow"
        Action   = ["cloudwatch:GetMetricStatistics"]
        Resource = "*"
      }
    ]
  })
}
